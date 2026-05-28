# Step 3 Path B: Manual `track_ai`

For everything that ADK doesn't cover. For each `file:line` match from Step 1c that is NOT captured by Path A, pick the closest pattern below and apply.

Always pass all four of `user_id`, `convo_id`, `model`, `provider`. See `REFERENCE.md` for what breaks if you skip one.

## Canonical shape

```python
import bentolabs_sdk.analytics as bento

bento.track_ai(
    event="user_message",
    user_id="user_42",
    convo_id="conv_abc",
    model="claude-3-5-sonnet-20241022",
    provider="anthropic",
    input="What's the capital of France?",
    output="Paris.",
)
```

One `track_ai` call ships one OTel span. Each kwarg becomes one span attribute the dashboard first-classes into a column.

## Pattern A: Single LLM call, no surrounding agent loop

The most common shape. Wrap one call in one `track_ai`.

**OpenAI chat completions, before:**

```python
resp = client.chat.completions.create(model="gpt-4o", messages=messages)
reply = resp.choices[0].message.content
```

**After:**

```python
import bentolabs_sdk.analytics as bento

resp = client.chat.completions.create(model="gpt-4o", messages=messages)
reply = resp.choices[0].message.content

bento.track_ai(
    event="chat_completion",
    user_id=request.user.id,
    convo_id=conversation_id,
    model="gpt-4o",
    provider="openai",
    input=messages,
    output=reply,
)
```

**Anthropic messages:** same shape, change `provider="anthropic"` and the model id.

**Bedrock:** `provider="aws_bedrock"` even when the model id starts with `anthropic.`. The Bedrock model id is ambiguous on purpose.

## Pattern B: Multi-step or tool-calling agent

Open a trajectory so the whole turn renders as one trace. Inner `track_ai` and `tool_span` calls parent to it automatically.

```python
import bentolabs_sdk.analytics as bento

with bento.begin(
    event="user_turn",
    user_id=request.user.id,
    convo_id=conversation_id,
    model="claude-3-5-sonnet-20241022",
    provider="anthropic",
    input=user_message,
) as interaction:
    plan = client.messages.create(model="claude-3-5-sonnet-20241022", messages=[...])
    bento.track_ai(event="plan", input=user_message, output=plan.content[0].text)

    with interaction.tool_span(name="web_search", input={"q": query}) as ts:
        results = run_search(query)
        ts.set_output(results)

    final = client.messages.create(model="claude-3-5-sonnet-20241022", messages=[...])
    interaction.update(output=final.content[0].text)
```

Nested trajectories must finish LIFO. The context-manager form guarantees correct nesting; the imperative `interaction.finish()` form does not.

## Pattern C: Tool / function-shaped work

Decorate the tool function. Bound arguments become `input.value`; the return value becomes `output.value`.

```python
@bento.tool
def web_search(query: str, limit: int = 10) -> list[str]:
    return [...]

@bento.tool(name="search", capture_input=False)  # for sensitive args
def search_with_secrets(api_key: str, query: str) -> list[str]:
    return [...]
```

## Pattern D: LangChain / LlamaIndex

These frameworks emit OTel spans natively. Wire `BentoLabsSpanProcessor` into the existing tracer provider (see `REFERENCE.md` "Lower-level: the OTel transport"). Do NOT wrap individual LangChain calls in `track_ai` — that would double-count.

## Pattern E: Streaming responses

`track_ai` once after the stream completes. Accumulate output, then call once:

```python
chunks = []
stream = client.chat.completions.create(model="gpt-4o", messages=messages, stream=True)
for chunk in stream:
    chunks.append(chunk.choices[0].delta.content or "")
full = "".join(chunks)

bento.track_ai(
    event="streamed_chat",
    user_id=user_id, convo_id=convo_id,
    model="gpt-4o", provider="openai",
    input=messages, output=full,
)
```

Per-token spans are not the right pattern; one span per completed exchange is.
