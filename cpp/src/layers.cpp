#include "layers.hpp"

#include <algorithm>
#include <cmath>

Tensor4D conv2d(const Tensor4D& x, const std::vector<float>& weight,
                const std::vector<float>& bias, const ConvLayer& layer) {
    int out_h = (x.h + 2 * layer.padding - layer.kernel) / layer.stride + 1;
    int out_w = (x.w + 2 * layer.padding - layer.kernel) / layer.stride + 1;
    int in_per_group = layer.in_c / layer.groups;
    int out_per_group = layer.out_c / layer.groups;

    Tensor4D y;
    y.n = x.n;
    y.c = layer.out_c;
    y.h = out_h;
    y.w = out_w;
    y.data.assign(static_cast<std::size_t>(y.n) * y.c * y.h * y.w, 0.0f);

    for (int n = 0; n < x.n; ++n) {
        for (int oc = 0; oc < layer.out_c; ++oc) {
            int group = oc / out_per_group;
            int ic_start = group * in_per_group;
            for (int oy = 0; oy < out_h; ++oy) {
                for (int ox = 0; ox < out_w; ++ox) {
                    float sum = bias[oc];
                    for (int icg = 0; icg < in_per_group; ++icg) {
                        int ic = ic_start + icg;
                        for (int ky = 0; ky < layer.kernel; ++ky) {
                            int iy = oy * layer.stride + ky - layer.padding;
                            if (iy < 0 || iy >= x.h) continue;
                            for (int kx = 0; kx < layer.kernel; ++kx) {
                                int ix = ox * layer.stride + kx - layer.padding;
                                if (ix < 0 || ix >= x.w) continue;
                                std::size_t widx = (((oc * in_per_group + icg) * layer.kernel + ky) * layer.kernel + kx);
                                sum += x.get(n, ic, iy, ix) * weight[widx];
                            }
                        }
                    }
                    y.set(n, oc, oy, ox, sum);
                }
            }
        }
    }
    return y;
}

void relu_inplace(Tensor4D& x) {
    for (float& v : x.data) {
        if (v < 0.0f) v = 0.0f;
    }
}

Tensor4D adaptive_avg_pool_1x1(const Tensor4D& x) {
    Tensor4D y;
    y.n = x.n;
    y.c = x.c;
    y.h = 1;
    y.w = 1;
    y.data.assign(static_cast<std::size_t>(x.n) * x.c, 0.0f);
    float denom = static_cast<float>(x.h * x.w);
    for (int n = 0; n < x.n; ++n) {
        for (int c = 0; c < x.c; ++c) {
            float sum = 0.0f;
            for (int y0 = 0; y0 < x.h; ++y0) {
                for (int x0 = 0; x0 < x.w; ++x0) {
                    sum += x.get(n, c, y0, x0);
                }
            }
            y.set(n, c, 0, 0, sum / denom);
        }
    }
    return y;
}

std::vector<float> flatten(const Tensor4D& x) {
    return x.data;
}

std::vector<float> linear(const std::vector<float>& x, const std::vector<float>& weight,
                          const std::vector<float>& bias, int out_features, int in_features) {
    std::vector<float> y(out_features, 0.0f);
    for (int out = 0; out < out_features; ++out) {
        float sum = bias[out];
        for (int in = 0; in < in_features; ++in) {
            sum += x[in] * weight[out * in_features + in];
        }
        y[out] = sum;
    }
    return y;
}

std::vector<float> softmax(const std::vector<float>& x) {
    float max_value = *std::max_element(x.begin(), x.end());
    std::vector<float> y(x.size(), 0.0f);
    float sum = 0.0f;
    for (std::size_t i = 0; i < x.size(); ++i) {
        y[i] = std::exp(x[i] - max_value);
        sum += y[i];
    }
    for (float& v : y) {
        v /= sum;
    }
    return y;
}
