#pragma once

#include "tensor.hpp"

#include <filesystem>
#include <string>
#include <vector>

TensorData read_tensor_file(const std::filesystem::path& path);
Tensor4D read_input_tensor(const std::filesystem::path& path);

void remove_output_dir(const std::filesystem::path& path);

void dump_tensor4d(int index, const std::string& name, const std::string& type,
                   const Tensor4D& x, const std::filesystem::path& out_root);

void dump_vector(int index, const std::string& name, const std::string& type,
                 const std::vector<float>& values, const std::vector<int>& shape,
                 const std::filesystem::path& out_root);
