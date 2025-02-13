// Copyright (c) OpenMMLab. All rights reserved.

#include "../decoding_config.h"
#include "../decoding_template.h"

namespace turbomind {

using namespace attention;

template bool invokeDecoding<Decoding<arch::Sm80, nv_bfloat16, uint8_t, 8, 64>>(const AttentionParams<nv_bfloat16>&);

template bool invokeDecoding<Decoding<arch::Sm80, nv_bfloat16, uint8_t, 16, 64>>(const AttentionParams<nv_bfloat16>&);

}  // namespace turbomind
