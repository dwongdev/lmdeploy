# Copyright (c) OpenMMLab. All rights reserved.
from lmdeploy.pytorch.config import ModelConfig

from .builder import AutoModelConfigBuilder


class LlavaHfModelConfigBuilder(AutoModelConfigBuilder):

    @classmethod
    def condition(cls, hf_config):
        """config."""
        return hf_config.architectures[0] in ['LlavaForConditionalGeneration', 'LlavaNextForConditionalGeneration']

    @classmethod
    def build(cls, hf_config, model_path: str = None, **kwargs):
        """Build llava hf."""
        text_config = hf_config.text_config
        hidden_size = getattr(text_config, 'hidden_size', 4096)
        num_attention_heads = getattr(text_config, 'num_attention_heads', 32)
        num_key_value_heads = getattr(text_config, 'num_key_value_heads', 32)
        num_hidden_layers = getattr(text_config, 'num_hidden_layers', 32)
        bos_token_id = getattr(text_config, 'bos_token_id', 1)
        eos_token_id = getattr(text_config, 'eos_token_id', 2)
        head_dim = hidden_size // num_attention_heads

        return ModelConfig(
            hidden_size=hidden_size,
            num_layers=num_hidden_layers,
            num_attention_heads=num_attention_heads,
            num_key_value_heads=num_key_value_heads,
            bos_token_id=bos_token_id,
            eos_token_id=eos_token_id,
            head_dim=head_dim,
            vocab_size=text_config.vocab_size,
            hf_config=hf_config,
        )
