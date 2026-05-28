"""Step 5a: smoke test for the manual track_ai path.

Run once after Step 2 (install) and Step 3 Path B (manual wrap). Set
BENTOLABS_API_KEY in the environment first. A row should appear in the
dashboard within seconds.
"""

import bentolabs_sdk.analytics as bento

bento.track_ai(
    event="hello_world",
    user_id="verify_user",
    convo_id="verify_conv",
    model="claude-3-5-sonnet-20241022",
    provider="anthropic",
    input="ping",
    output="pong",
)
bento.flush()
print("Sent hello_world. Check the dashboard at https://platform.bentolabs.ai")
