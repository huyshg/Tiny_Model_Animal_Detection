# Fused Execution Plan

The C++ pipeline dumps 34 executable outputs. In hardware, `softmax` can be replaced by `argmax` over the 10 logits.

| Step | Operation |
|---:|---|
| 0 | ConvBN fused `features.0 + features.1` |
| 1 | ReLU `features.2` |
| 2 | ConvBN fused `features.3.block.0 + features.3.block.1` |
| 3 | ReLU `features.3.block.2` |
| 4 | ConvBN fused `features.3.block.3 + features.3.block.4` |
| 5 | ReLU `features.3.block.5` |
| 6 | ConvBN fused `features.4.block.0 + features.4.block.1` |
| 7 | ReLU `features.4.block.2` |
| 8 | ConvBN fused `features.4.block.3 + features.4.block.4` |
| 9 | ReLU `features.4.block.5` |
| 10 | ConvBN fused `features.5.block.0 + features.5.block.1` |
| 11 | ReLU `features.5.block.2` |
| 12 | ConvBN fused `features.5.block.3 + features.5.block.4` |
| 13 | ReLU `features.5.block.5` |
| 14 | ConvBN fused `features.6.block.0 + features.6.block.1` |
| 15 | ReLU `features.6.block.2` |
| 16 | ConvBN fused `features.6.block.3 + features.6.block.4` |
| 17 | ReLU `features.6.block.5` |
| 18 | ConvBN fused `features.7.block.0 + features.7.block.1` |
| 19 | ReLU `features.7.block.2` |
| 20 | ConvBN fused `features.7.block.3 + features.7.block.4` |
| 21 | ReLU `features.7.block.5` |
| 22 | ConvBN fused `features.8.block.0 + features.8.block.1` |
| 23 | ReLU `features.8.block.2` |
| 24 | ConvBN fused `features.8.block.3 + features.8.block.4` |
| 25 | ReLU `features.8.block.5` |
| 26 | ConvBN fused `features.9.block.0 + features.9.block.1` |
| 27 | ReLU `features.9.block.2` |
| 28 | ConvBN fused `features.9.block.3 + features.9.block.4` |
| 29 | ReLU `features.9.block.5` |
| 30 | Adaptive average pool 1x1 |
| 31 | Flatten |
| 32 | Linear classifier |
| 33 | Argmax logits for predicted class |
