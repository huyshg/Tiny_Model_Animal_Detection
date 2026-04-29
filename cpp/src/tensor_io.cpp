#include "tensor_io.hpp"

#include <cctype>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace fs = std::filesystem;

static std::vector<int> parse_shape(const std::string& line) {
    std::vector<int> shape;
    std::size_t left = line.find('[');
    std::size_t right = line.find(']');
    if (left == std::string::npos || right == std::string::npos || right <= left + 1) {
        return shape;
    }
    std::string inside = line.substr(left + 1, right - left - 1);
    std::stringstream ss(inside);
    std::string item;
    while (std::getline(ss, item, ',')) {
        std::stringstream item_stream(item);
        int value = 0;
        item_stream >> value;
        shape.push_back(value);
    }
    return shape;
}

static std::string make_dump_folder_name(int index, const std::string& name) {
    std::ostringstream folder_name;
    folder_name << std::setw(3) << std::setfill('0') << index << "_";
    for (char ch : name) {
        bool ok = std::isalnum(static_cast<unsigned char>(ch)) || ch == '_';
        folder_name << (ok ? ch : '_');
    }
    return folder_name.str();
}

TensorData read_tensor_file(const fs::path& path) {
    std::ifstream fin(path);
    if (!fin) {
        throw std::runtime_error("Cannot open tensor file: " + path.string());
    }
    TensorData tensor;
    std::string line;
    bool in_values = false;
    while (std::getline(fin, line)) {
        if (line.rfind("Shape", 0) == 0) {
            tensor.shape = parse_shape(line);
        } else if (line == "Values:") {
            in_values = true;
        } else if (in_values) {
            std::size_t colon = line.find(':');
            if (colon != std::string::npos) {
                tensor.values.push_back(std::stof(line.substr(colon + 1)));
            }
        }
    }
    return tensor;
}

Tensor4D read_input_tensor(const fs::path& path) {
    TensorData t = read_tensor_file(path);
    if (t.shape.size() != 4) {
        throw std::runtime_error("Input tensor must have 4 dimensions");
    }
    Tensor4D x;
    x.n = t.shape[0];
    x.c = t.shape[1];
    x.h = t.shape[2];
    x.w = t.shape[3];
    x.data = std::move(t.values);
    return x;
}

void remove_output_dir(const fs::path& path) {
    if (fs::exists(path)) {
        fs::remove_all(path);
    }
    fs::create_directories(path);
}

static void write_values(const fs::path& folder, const std::string& tensor_name,
                         const std::vector<int>& shape, const std::vector<float>& values,
                         const std::string& layer_type) {
    fs::create_directories(folder);
    {
        std::ofstream fout(folder / "output.txt");
        fout << "========================================\n";
        fout << "TENSOR DATA\n";
        fout << "========================================\n\n";
        fout << "Tensor name : " << tensor_name << "\n";
        fout << "Shape       : [";
        for (std::size_t i = 0; i < shape.size(); ++i) {
            if (i) fout << ", ";
            fout << shape[i];
        }
        fout << "]\n";
        fout << "Num values  : " << values.size() << "\n";
        fout << "Dtype       : float32\n\n";
        fout << "Values:\n";
        fout << std::fixed << std::setprecision(10);
        for (std::size_t i = 0; i < values.size(); ++i) {
            fout << i << ": " << values[i] << "\n";
        }
    }
    {
        std::ofstream info(folder / "layer_info.txt");
        info << "========================================\n";
        info << "CPP OUTPUT LAYER INFO\n";
        info << "========================================\n\n";
        info << "Layer name   : " << tensor_name << "\n";
        info << "Layer type   : " << layer_type << "\n";
        info << "Shape        : [";
        for (std::size_t i = 0; i < shape.size(); ++i) {
            if (i) info << ", ";
            info << shape[i];
        }
        info << "]\n";
    }
}

void dump_tensor4d(int index, const std::string& name, const std::string& type,
                   const Tensor4D& x, const fs::path& out_root) {
    write_values(out_root / make_dump_folder_name(index, name), name, {x.n, x.c, x.h, x.w}, x.data, type);
}

void dump_vector(int index, const std::string& name, const std::string& type,
                 const std::vector<float>& values, const std::vector<int>& shape,
                 const fs::path& out_root) {
    write_values(out_root / make_dump_folder_name(index, name), name, shape, values, type);
}
