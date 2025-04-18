# Copyright (c) OpenMMLab. All rights reserved.
from lmdeploy.pytorch.config import ModelConfig

from .builder import AutoModelConfigBuilder


class ChatGLMModelConfigBuilder(AutoModelConfigBuilder):

    @classmethod
    def condition(cls, hf_config):
        """config."""
        return hf_config.model_type == 'chatglm'

    @classmethod
    def build(cls, hf_config, model_path: str = None, **kwargs):
        """build."""
        head_dim = hf_config.hidden_size // hf_config.num_attention_heads
        bos_token_id = hf_config.bos_token_id
        if bos_token_id is None:
            bos_token_id = hf_config.pad_token_id

        if hf_config.multi_query_attention:
            num_key_value_heads = hf_config.multi_query_group_num
        else:
            num_key_value_heads = hf_config.num_attention_heads

        tp = kwargs.get('tp', 1)
        # update num_kv_heads for tp mode
        num_key_value_heads = cls.update_num_kv_heads(hf_config, tp, num_key_value_heads)

        cfg = ModelConfig(hidden_size=hf_config.hidden_size,
                          num_layers=hf_config.num_layers,
                          num_attention_heads=hf_config.num_attention_heads,
                          num_key_value_heads=num_key_value_heads,
                          bos_token_id=bos_token_id,
                          eos_token_id=hf_config.eos_token_id,
                          head_dim=head_dim,
                          vocab_size=hf_config.padded_vocab_size)
        # glm-4v
        if hasattr(hf_config, 'vision_config'):
            cfg.cogvlm_style = True
        return cfg
