#include "tensor.hpp"

float Tensor4D::get(int ni, int ci, int yi, int xi) const {
    return data[((ni * c + ci) * h + yi) * w + xi];
}

void Tensor4D::set(int ni, int ci, int yi, int xi, float value) {
    data[((ni * c + ci) * h + yi) * w + xi] = value;
}
