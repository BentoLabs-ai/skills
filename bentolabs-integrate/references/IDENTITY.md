# Step 4: Source `user_id` and `convo_id`

These two identifiers unlock the dashboard's user filter and conversation timeline. Two patterns; pick one and apply consistently.

## Pattern 1: Init-time getters (preferred for Path A; works for Path B too)

Register zero-arg callables at `bento.init(...)` once. Bento invokes them on every span (whether captured by an integration or emitted by `bento.track_ai`) and writes the result to `gen_ai.user.id` / `gen_ai.conversation.id` / `langfuse.tags`.

```python
# FastAPI / Starlette: from a ContextVar set by auth middleware
from contextvars import ContextVar

current_user: ContextVar[str | None] = ContextVar("current_user", default=None)
current_convo: ContextVar[str | None] = ContextVar("current_convo", default=None)

bento.init(user_id=current_user.get, session_id=current_convo.get)

# In middleware:
@app.middleware("http")
async def attach_identity(request, call_next):
    current_user.set(await resolve_user_id(request))
    current_convo.set(request.path_params.get("convo_id"))
    return await call_next(request)
```

Why a callable, not a value: the SDK calls the function on every span. A static value would only fit single-tenant apps. A getter that raises is swallowed; the field is dropped for that span and the host app is never affected.

Partial `bento.init(...)` calls preserve previously registered getters. Bare `init()` no-ops on identity. `init(user_id=None)` explicitly clears just `user_id`.

## Pattern 2: Per-call kwargs (Path B only)

Thread `user_id` and `convo_id` from the request entry point down to each `bento.track_ai(...)` call site.

| Framework | `user_id` typically lives in | `convo_id` typically lives in |
|---|---|---|
| FastAPI / Starlette | `request.state.user.id` after auth middleware, or a `Depends(get_current_user)` | path param `/chats/{convo_id}/messages`, or a request body field |
| Django | `request.user.id` (via `AuthenticationMiddleware`) | URL kwarg or POST body |
| Flask | `g.user.id` or `flask_login.current_user.id` | request arg or session |
| CLI / script | argparse arg or `os.getlogin()` | a UUID minted at script start |

If no auth exists yet, pass a stable anonymous id (`request.client.host`, a cookie, or a `uuid.uuid4()` per session). Never pass `None`; a missing `user_id` silently disables the user filter.

`convo_id` must be the **same string across every turn of one conversation**. A common bug is minting a new UUID per request, which fragments the conversation timeline.

## Late-binding identity (either pattern)

When identity becomes known mid-flow (for example, authentication completes inside an open trajectory):

```python
with bento.begin(event="user_turn") as interaction:
    user_id, session_id = await authenticate(request)
    bento.update_current_trace(user_id=user_id, session_id=session_id)
    # rest of the work; root span has identity now
```

For per-task scoped overrides (a worker that received identity over a queue):

```python
with bento.propagate_attributes(user_id="u_42", session_id="conv_99"):
    await agent.run(query)        # every span tagged automatically
```

Each `propagate_attributes` kwarg takes three values: omitted (inherit), a value (override), or explicit `None` (clear for the scope, shadowing the outer source).
