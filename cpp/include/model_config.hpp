#pragma once

#include <string>
#include <vector>

struct ConvLayer {
    std::string name;
    std::string folder;
    int in_c;
    int out_c;
    int in_h;
    int in_w;
    int kernel;
    int stride;
    int padding;
    int groups;
};

std::vector<ConvLayer> make_conv_layers();
std::vector<std::string> make_relu_layer_names();
