// Copyright (c) OpenMMLab. All rights reserved.

#include "attention.h"
#include "attention_config.h"
#include "src/turbomind/kernels/attention/arch.h"
#include "src/turbomind/models/llama/llama_utils.h"
#include "src/turbomind/utils/cuda_utils.h"

namespace turbomind {

template<class Kernel>
void invokeAttention(const typename Kernel::ParamType& params);

template<class T>
void dispatchAttention(const AttentionParams<T>& params)
{
    using namespace attention;
    auto dispatch = [&](const auto dim) {
        constexpr int kHeadDim = dim;
        if (params.arch >= 80) {
            using Config = AttentionConfig<arch::Sm80, T, kHeadDim, CacheType::kLinear>;
            return invokeAttention<typename Config::Kernel>(params);
        }
        if constexpr (!std::is_same_v<T, nv_bfloat16>) {
            if (params.arch == 75) {
                return invokeAttention<typename AttentionConfig<arch::Sm75, T, kHeadDim, CacheType::kLinear>::Kernel>(
                    params);
            }
            else if (params.arch >= 70) {
                return invokeAttention<typename AttentionConfig<arch::Sm70, T, kHeadDim, CacheType::kLinear>::Kernel>(
                    params);
            }
        }
        else {
            if (params.arch < 80) {
                TM_LOG_ERROR(
                    "CUDA architecture sm%d does not support data type 'bfloat16'. Please specify dtype 'float16'",
                    params.arch);
            }
        }
        FT_CHECK(0);
    };

    if (params.size_per_head == 64) {
        return dispatch(std::integral_constant<int, 64>{});
    }
    else if (params.size_per_head == 128) {
        return dispatch(std::integral_constant<int, 128>{});
    }

    if (params.size_per_head == 192) {
        using Config = AttentionConfig<arch::Sm80, T, 192, CacheType::kLinear>;
        return invokeAttention<typename Config::Kernel>(params);
    }

    FT_CHECK(0);
}

template void dispatchAttention(const AttentionParams<half>& params);
#if ENABLE_BF16
template void dispatchAttention(const AttentionParams<nv_bfloat16>& params);
#endif

}  // namespace turbomind
