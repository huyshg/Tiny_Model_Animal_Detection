#pragma once

#include <vector>

struct Tensor4D {
    int n = 1;
    int c = 0;
    int h = 0;
    int w = 0;
    std::vector<float> data;

    float get(int ni, int ci, int yi, int xi) const;
    void set(int ni, int ci, int yi, int xi, float value);
};

struct TensorData {
    std::vector<int> shape;
    std::vector<float> values;
};
