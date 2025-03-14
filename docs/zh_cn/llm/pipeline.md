# LLM 离线推理 pipeline

本文通过一些例子展示 pipeline 的基本用法。

pipeline API 详细的接口说明，请阅读[此处](https://lmdeploy.readthedocs.io/zh-cn/latest/api/pipeline.html)

## 使用方法

### "Hello, world" 示例

```python
from lmdeploy import pipeline

pipe = pipeline('internlm/internlm2_5-7b-chat')
response = pipe(['Hi, pls intro yourself', 'Shanghai is'])
print(response)
```

在这个例子中，pipeline 默认申请一定比例显存，用来存储推理过程中产生的 k/v。比例由参数 `TurbomindEngineConfig.cache_max_entry_count` 控制。

LMDeploy 在研发过程中，k/v cache 比例的设定策略有变更，以下为变更记录：

1. `v0.2.0 <= lmdeploy <= v0.2.1`

   默认比例为 0.5，表示 **GPU总显存**的 50% 被分配给 k/v cache。 对于 7B 模型来说，如果显存小于 40G，会出现 OOM。当遇到 OOM 时，请按照下面的方法，酌情降低 k/v cache 占比：

   ```python
   from lmdeploy import pipeline, TurbomindEngineConfig

   # 调低 k/v cache内存占比调整为总显存的 20%
   backend_config = TurbomindEngineConfig(cache_max_entry_count=0.2)

   pipe = pipeline('internlm/internlm2_5-7b-chat',
                   backend_config=backend_config)
   response = pipe(['Hi, pls intro yourself', 'Shanghai is'])
   print(response)
   ```

2. `lmdeploy > v0.2.1`

   分配策略改为从**空闲显存**中按比例为 k/v cache 开辟空间。默认比例值调整为 0.8。如果遇到 OOM，类似上面的方法，请酌情减少比例值，降低 k/v cache 的内存占用量

### 设置多卡并行

```python
from lmdeploy import pipeline, TurbomindEngineConfig

backend_config = TurbomindEngineConfig(tp=2)
pipe = pipeline('internlm/internlm2_5-7b-chat',
                backend_config=backend_config)
response = pipe(['Hi, pls intro yourself', 'Shanghai is'])
print(response)
```

### 设置随机采样参数

```python
from lmdeploy import pipeline, GenerationConfig, TurbomindEngineConfig

backend_config = TurbomindEngineConfig(tp=2)
gen_config = GenerationConfig(top_p=0.8,
                              top_k=40,
                              temperature=0.8,
                              max_new_tokens=1024)
pipe = pipeline('internlm/internlm2_5-7b-chat',
                backend_config=backend_config)
response = pipe(['Hi, pls intro yourself', 'Shanghai is'],
                gen_config=gen_config)
print(response)
```

### 使用 OpenAI 格式的 prompt

```python
from lmdeploy import pipeline, GenerationConfig, TurbomindEngineConfig

backend_config = TurbomindEngineConfig(tp=2)
gen_config = GenerationConfig(top_p=0.8,
                              top_k=40,
                              temperature=0.8,
                              max_new_tokens=1024)
pipe = pipeline('internlm/internlm2_5-7b-chat',
                backend_config=backend_config)
prompts = [[{
    'role': 'user',
    'content': 'Hi, pls intro yourself'
}], [{
    'role': 'user',
    'content': 'Shanghai is'
}]]
response = pipe(prompts,
                gen_config=gen_config)
print(response)
```

### 流式输出

```python
from lmdeploy import pipeline, GenerationConfig, TurbomindEngineConfig

backend_config = TurbomindEngineConfig(tp=2)
gen_config = GenerationConfig(top_p=0.8,
                              top_k=40,
                              temperature=0.8,
                              max_new_tokens=1024)
pipe = pipeline('internlm/internlm2_5-7b-chat',
                backend_config=backend_config)
prompts = [[{
    'role': 'user',
    'content': 'Hi, pls intro yourself'
}], [{
    'role': 'user',
    'content': 'Shanghai is'
}]]
for item in pipe.stream_infer(prompts, gen_config=gen_config):
    print(item)
```

### 获取生成 token 的 logits

```python
from lmdeploy import pipeline, GenerationConfig

pipe = pipeline('internlm/internlm2_5-7b-chat')

gen_config=GenerationConfig(output_logits='generation'
                            max_new_tokens=10)
response = pipe(['Hi, pls intro yourself', 'Shanghai is'],
                gen_config=gen_config)
logits = [x.logits for x in response]
```

### 获取生成 token 最后一层的 hidden_states

```python
from lmdeploy import pipeline, GenerationConfig

pipe = pipeline('internlm/internlm2_5-7b-chat')

gen_config=GenerationConfig(output_last_hidden_state='generation',
                            max_new_tokens=10)
response = pipe(['Hi, pls intro yourself', 'Shanghai is'],
                gen_config=gen_config)
hidden_states = [x.last_hidden_state for x in response]
```

### 计算 ppl

```python
from transformers import AutoTokenizer
from lmdeploy import pipeline


model_repoid_or_path = 'internlm/internlm2_5-7b-chat'
pipe = pipeline(model_repoid_or_path)
tokenizer = AutoTokenizer.from_pretrained(model_repoid_or_path, trust_remote_code=True)
messages = [
   {"role": "user", "content": "Hello, how are you?"},
]
input_ids = tokenizer.apply_chat_template(messages)

# logits is a list of tensor
logits = pipe.get_logits(input_ids)
print(logits)

# ppl is a list of float numbers
ppl = pipe.get_ppl(input_ids)
print(ppl)
```

```{note}
当 input_ids 过长时，可能会出现 OOM 错误，请小心应用
get_ppl 返回的是 cross entropy loss，没有在之后加 exp 操作
```

### 使用 PyTorchEngine

需要先安装 triton

```shell
pip install triton>=2.1.0
```

```python
from lmdeploy import pipeline, GenerationConfig, PytorchEngineConfig

backend_config = PytorchEngineConfig(session_len=2048)
gen_config = GenerationConfig(top_p=0.8,
                              top_k=40,
                              temperature=0.8,
                              max_new_tokens=1024)
pipe = pipeline('internlm/internlm2_5-7b-chat',
                backend_config=backend_config)
prompts = [[{
    'role': 'user',
    'content': 'Hi, pls intro yourself'
}], [{
    'role': 'user',
    'content': 'Shanghai is'
}]]
response = pipe(prompts, gen_config=gen_config)
print(response)
```

### LoRA 模型推理

```python
from lmdeploy import pipeline, GenerationConfig, PytorchEngineConfig

backend_config = PytorchEngineConfig(session_len=2048,
                                     adapters=dict(lora_name_1='chenchi/lora-chatglm2-6b-guodegang'))
gen_config = GenerationConfig(top_p=0.8,
                              top_k=40,
                              temperature=0.8,
                              max_new_tokens=1024)
pipe = pipeline('THUDM/chatglm2-6b',
                backend_config=backend_config)
prompts = [[{
    'role': 'user',
    'content': '您猜怎么着'
}]]
response = pipe(prompts, gen_config=gen_config, adapter_name='lora_name_1')
print(response)
```

### 释放 pipeline

您可以通过调用其 `close()` 方法来显式释放 pipeline，或者，也可以使用 `with` 语句，如下所示：

```python
from lmdeploy import pipeline

with pipeline('internlm/internlm2_5-7b-chat') as pipe:
    response = pipe(['Hi, pls intro yourself', 'Shanghai is'])
    print(response)
```

## 常见问题

- **RuntimeError: An attempt has been made to start a new process before the current process has finished its bootstrapping phase**.

  如果你在使用 tp>1 和 pytorch 后端的时候，遇到了这个错误。请确保 python 脚本中有下面内容作为入口

  ```python
  if __name__ == '__main__':
  ```

  一般来说，在多线程或多进程上下文中，可能需要确保初始化代码只执行一次。这时候，`if __name__ == '__main__':` 可以帮助确保这些初始化代码只在主程序执行，而不会在每个新创建的进程或线程中重复执行。

- 自定义对话模板，请参考[chat_template.md](../advance/chat_template.md)

- 如果 lora 的权重有对应的对话模板，可以先注册对话模板到 lmdeploy，然后 adapter 名为对话模板名使用即可
