#include "inference.hpp"

#include "layers.hpp"
#include "model_config.hpp"
#include "tensor_io.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace fs = std::filesystem;

int run_model_inference(const fs::path& project_root) {
    fs::path param_root = project_root / "parameters_by_layer_fused";
    fs::path output_root = project_root / "output_cpp";
    remove_output_dir(output_root);

    Tensor4D x = read_input_tensor(project_root / "data" / "preprocessed_input.txt");
    std::vector<ConvLayer> convs = make_conv_layers();
    std::vector<std::string> relu_names = make_relu_layer_names();

    int out_index = 0;
    int conv_index = 0;
    int relu_index = 0;

    auto run_conv = [&]() {
        const ConvLayer& layer = convs[conv_index++];
        TensorData w = read_tensor_file(param_root / layer.folder / "weight.txt");
        TensorData b = read_tensor_file(param_root / layer.folder / "bias.txt");
        x = conv2d(x, w.values, b.values, layer);
        dump_tensor4d(out_index++, layer.name, "Conv2d + BatchNorm2d fused", x, output_root);
    };

    auto run_relu = [&]() {
        std::string name = relu_names[relu_index++];
        relu_inplace(x);
        dump_tensor4d(out_index++, name, "ReLU", x, output_root);
    };

    run_conv();
    run_relu();
    for (int block = 0; block < 7; ++block) {
        run_conv();
        run_relu();
        run_conv();
        run_relu();
    }

    x = adaptive_avg_pool_1x1(x);
    dump_tensor4d(out_index++, "pool", "AdaptiveAvgPool2d", x, output_root);

    std::vector<float> flat = flatten(x);
    dump_vector(out_index++, "classifier.0", "Flatten", flat, {1, static_cast<int>(flat.size())}, output_root);

    TensorData lw = read_tensor_file(param_root / "015_classifier_1" / "weight.txt");
    TensorData lb = read_tensor_file(param_root / "015_classifier_1" / "bias.txt");
    std::vector<float> logits = linear(flat, lw.values, lb.values, 10, 307);
    dump_vector(out_index++, "classifier.1", "Linear", logits, {1, 10}, output_root);

    std::vector<float> probs = softmax(logits);
    dump_vector(out_index++, "softmax", "Softmax", probs, {1, 10}, output_root);

    int top_index = static_cast<int>(std::max_element(probs.begin(), probs.end()) - probs.begin());
    std::ofstream pred(output_root / "prediction.txt");
    pred << "Top index  : " << top_index << "\n";
    pred << "Top prob   : " << std::fixed << std::setprecision(10) << probs[top_index] << "\n";
    pred << "Probabilities:\n";
    for (std::size_t i = 0; i < probs.size(); ++i) {
        pred << i << ": " << probs[i] << "\n";
    }

    std::cout << "C++ outputs written to " << output_root << "\n";
    std::cout << "Dumped " << out_index << " executable layers\n";
    return 0;
}
