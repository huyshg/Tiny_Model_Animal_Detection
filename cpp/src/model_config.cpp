#include "model_config.hpp"

std::vector<ConvLayer> make_conv_layers() {
    return {
        {"features.0_fused_features.1", "000_features_0_conv_bn_fused", 3, 25, 160, 160, 3, 2, 1, 1},
        {"features.3.block.0_fused_features.3.block.1", "001_features_3_block_0_conv_bn_fused", 25, 25, 80, 80, 3, 1, 1, 25},
        {"features.3.block.3_fused_features.3.block.4", "002_features_3_block_3_conv_bn_fused", 25, 51, 80, 80, 1, 1, 0, 1},
        {"features.4.block.0_fused_features.4.block.1", "003_features_4_block_0_conv_bn_fused", 51, 51, 80, 80, 3, 2, 1, 51},
        {"features.4.block.3_fused_features.4.block.4", "004_features_4_block_3_conv_bn_fused", 51, 76, 40, 40, 1, 1, 0, 1},
        {"features.5.block.0_fused_features.5.block.1", "005_features_5_block_0_conv_bn_fused", 76, 76, 40, 40, 3, 1, 1, 76},
        {"features.5.block.3_fused_features.5.block.4", "006_features_5_block_3_conv_bn_fused", 76, 102, 40, 40, 1, 1, 0, 1},
        {"features.6.block.0_fused_features.6.block.1", "007_features_6_block_0_conv_bn_fused", 102, 102, 40, 40, 3, 2, 1, 102},
        {"features.6.block.3_fused_features.6.block.4", "008_features_6_block_3_conv_bn_fused", 102, 153, 20, 20, 1, 1, 0, 1},
        {"features.7.block.0_fused_features.7.block.1", "009_features_7_block_0_conv_bn_fused", 153, 153, 20, 20, 3, 1, 1, 153},
        {"features.7.block.3_fused_features.7.block.4", "010_features_7_block_3_conv_bn_fused", 153, 204, 20, 20, 1, 1, 0, 1},
        {"features.8.block.0_fused_features.8.block.1", "011_features_8_block_0_conv_bn_fused", 204, 204, 20, 20, 3, 2, 1, 204},
        {"features.8.block.3_fused_features.8.block.4", "012_features_8_block_3_conv_bn_fused", 204, 256, 10, 10, 1, 1, 0, 1},
        {"features.9.block.0_fused_features.9.block.1", "013_features_9_block_0_conv_bn_fused", 256, 256, 10, 10, 3, 1, 1, 256},
        {"features.9.block.3_fused_features.9.block.4", "014_features_9_block_3_conv_bn_fused", 256, 307, 10, 10, 1, 1, 0, 1},
    };
}

std::vector<std::string> make_relu_layer_names() {
    return {
        "features.2", "features.3.block.2", "features.3.block.5",
        "features.4.block.2", "features.4.block.5",
        "features.5.block.2", "features.5.block.5",
        "features.6.block.2", "features.6.block.5",
        "features.7.block.2", "features.7.block.5",
        "features.8.block.2", "features.8.block.5",
        "features.9.block.2", "features.9.block.5",
    };
}
