#include "layers.hpp"
#include "model_config.hpp"
#include "tensor_io.hpp"

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace fs = std::filesystem;

struct LoadedConv {
    ConvLayer cfg;
    std::vector<float> weight;
    std::vector<float> bias;
};

struct Sample {
    std::string filename;
    std::string label;
};

static std::vector<std::string> class_names() {
    return {"cane", "cavallo", "elefante", "farfalla", "gallina",
            "gatto", "mucca", "pecora", "ragno", "scoiattolo"};
}

static std::vector<std::string> split_csv_line(const std::string& line) {
    std::vector<std::string> fields;
    std::string current;
    bool in_quotes = false;
    for (char ch : line) {
        if (ch == '"') {
            in_quotes = !in_quotes;
        } else if (ch == ',' && !in_quotes) {
            fields.push_back(current);
            current.clear();
        } else {
            current.push_back(ch);
        }
    }
    fields.push_back(current);
    return fields;
}

static std::vector<Sample> read_samples(const fs::path& labels_csv) {
    std::ifstream fin(labels_csv);
    if (!fin) {
        throw std::runtime_error("Cannot open labels csv: " + labels_csv.string());
    }
    std::vector<Sample> samples;
    std::string line;
    std::getline(fin, line);
    while (std::getline(fin, line)) {
        if (line.empty()) continue;
        std::vector<std::string> fields = split_csv_line(line);
        if (fields.size() < 2) {
            throw std::runtime_error("Bad labels.csv row: " + line);
        }
        samples.push_back({fields[0], fields[1]});
    }
    return samples;
}

static std::vector<LoadedConv> load_convs(const fs::path& param_root) {
    std::vector<LoadedConv> loaded;
    for (const ConvLayer& cfg : make_conv_layers()) {
        TensorData w = read_tensor_file(param_root / cfg.folder / "weight.txt");
        TensorData b = read_tensor_file(param_root / cfg.folder / "bias.txt");
        loaded.push_back({cfg, std::move(w.values), std::move(b.values)});
    }
    return loaded;
}

static int predict_one(const Tensor4D& input,
                       const std::vector<LoadedConv>& convs,
                       const std::vector<float>& linear_weight,
                       const std::vector<float>& linear_bias) {
    Tensor4D x = input;
    int conv_index = 0;

    auto run_conv = [&]() {
        const LoadedConv& layer = convs[conv_index++];
        x = conv2d(x, layer.weight, layer.bias, layer.cfg);
    };

    run_conv();
    relu_inplace(x);
    for (int block = 0; block < 7; ++block) {
        run_conv();
        relu_inplace(x);
        run_conv();
        relu_inplace(x);
    }

    x = adaptive_avg_pool_1x1(x);
    std::vector<float> flat = flatten(x);
    std::vector<float> logits = linear(flat, linear_weight, linear_bias, 10, 307);
    return static_cast<int>(std::max_element(logits.begin(), logits.end()) - logits.begin());
}

static fs::path input_path_for(const fs::path& input_dir, const std::string& filename) {
    fs::path p(filename);
    return input_dir / (p.stem().string() + ".txt");
}

int main(int argc, char** argv) {
    try {
        fs::path project_root = "..";
        if (argc >= 2) {
            project_root = argv[1];
        }

        fs::path param_root = project_root / "parameters_by_layer_fused";
        fs::path input_dir = project_root / "data" / "batch_inputs";
        fs::path labels_csv = project_root / "labels.csv";
        fs::path report_path = project_root / "cpp_batch_accuracy_report.csv";

        std::vector<std::string> names = class_names();
        std::unordered_map<std::string, int> label_to_index;
        for (int i = 0; i < static_cast<int>(names.size()); ++i) {
            label_to_index[names[i]] = i;
        }

        std::vector<Sample> samples = read_samples(labels_csv);
        std::vector<LoadedConv> convs = load_convs(param_root);
        TensorData lw = read_tensor_file(param_root / "015_classifier_1" / "weight.txt");
        TensorData lb = read_tensor_file(param_root / "015_classifier_1" / "bias.txt");

        std::ofstream report(report_path);
        if (!report) {
            throw std::runtime_error("Cannot open report for writing: " + report_path.string());
        }
        report << "filename,true_label,true_index,pred_label,pred_index,correct\n";

        auto start_time = std::chrono::steady_clock::now();
        int correct = 0;
        for (int i = 0; i < static_cast<int>(samples.size()); ++i) {
            const Sample& sample = samples[i];
            auto it = label_to_index.find(sample.label);
            if (it == label_to_index.end()) {
                throw std::runtime_error("Unknown label: " + sample.label);
            }

            Tensor4D input = read_input_tensor(input_path_for(input_dir, sample.filename));
            int pred = predict_one(input, convs, lw.values, lb.values);
            int truth = it->second;
            bool ok = pred == truth;
            if (ok) correct++;

            report << sample.filename << "," << sample.label << "," << truth << ","
                   << names[pred] << "," << pred << "," << (ok ? "pass" : "fail") << "\n";

            if ((i + 1) % 50 == 0 || i + 1 == static_cast<int>(samples.size())) {
                double acc = 100.0 * correct / static_cast<double>(i + 1);
                std::cout << "Processed " << (i + 1) << "/" << samples.size()
                          << " | accuracy = " << std::fixed << std::setprecision(2)
                          << acc << "%\n";
            }
        }

        auto end_time = std::chrono::steady_clock::now();
        double seconds = std::chrono::duration<double>(end_time - start_time).count();
        double accuracy = 100.0 * correct / static_cast<double>(samples.size());

        std::ofstream summary(project_root / "cpp_batch_accuracy_summary.txt");
        summary << "Total images : " << samples.size() << "\n";
        summary << "Correct      : " << correct << "\n";
        summary << "Accuracy     : " << std::fixed << std::setprecision(4) << accuracy << "%\n";
        summary << "Elapsed sec  : " << std::fixed << std::setprecision(3) << seconds << "\n";

        std::cout << "========================================\n";
        std::cout << "C++ BATCH ACCURACY\n";
        std::cout << "========================================\n";
        std::cout << "Total images : " << samples.size() << "\n";
        std::cout << "Correct      : " << correct << "\n";
        std::cout << "Accuracy     : " << std::fixed << std::setprecision(4) << accuracy << "%\n";
        std::cout << "Elapsed sec  : " << std::fixed << std::setprecision(3) << seconds << "\n";
        std::cout << "Report       : " << report_path << "\n";
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "ERROR: " << ex.what() << "\n";
        return 1;
    }
}
