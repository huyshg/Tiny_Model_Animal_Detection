#pragma once

#include "model_config.hpp"
#include "tensor.hpp"

#include <vector>

Tensor4D conv2d(const Tensor4D& x, const std::vector<float>& weight,
                const std::vector<float>& bias, const ConvLayer& layer);

void relu_inplace(Tensor4D& x);
Tensor4D adaptive_avg_pool_1x1(const Tensor4D& x);
std::vector<float> flatten(const Tensor4D& x);

std::vector<float> linear(const std::vector<float>& x, const std::vector<float>& weight,
                          const std::vector<float>& bias, int out_features, int in_features);

std::vector<float> softmax(const std::vector<float>& x);
