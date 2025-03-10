// Copyright (c) OpenMMLab. All rights reserved.

#include "../decoding_config.h"
#include "../decoding_template.h"

namespace turbomind {

using namespace attention;

template bool invokeDecoding<Decoding<arch::Sm80, half, uint4_t, 8, 64>>(const AttentionParams<half>&);

template bool invokeDecoding<Decoding<arch::Sm80, half, uint4_t, 16, 64>>(const AttentionParams<half>&);

}  // namespace turbomind
