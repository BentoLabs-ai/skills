"""Step 5: smoke test that Bento ingest is working.

Run once after Step 4 (porting code). Set BENTOLABS_API_KEY in the
environment first. A row should appear in the dashboard within seconds.

Do NOT uninstall the source SDK (raindrop-ai or langfuse) until this
verify passes AND every real call site you ported renders a complete
row in the dashboard.
"""

import bentolabs_sdk.analytics as bento

bento.track_ai(
    event="migration_verify",
    user_id="migration_user",
    convo_id="migration_conv",
    model="claude-3-5-sonnet-20241022",
    provider="anthropic",
    input="migration smoke test",
    output="ok",
)
bento.flush()
print("Sent migration_verify event. Check the dashboard at https://platform.bentolabs.ai")
