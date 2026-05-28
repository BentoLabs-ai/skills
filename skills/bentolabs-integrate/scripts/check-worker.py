"""Step 5b: confirm the SDK's background worker is alive.

If `OtelBatchSpanRecordProcessor` does NOT appear in the thread list,
bento.init() failed silently or SDK calls are happening before init
resolved. Re-check Step 2 (install) and BENTOLABS_API_KEY.
"""

import threading

import bentolabs_sdk.analytics as bento

bento.init()
threads = [t.name for t in threading.enumerate()]
print(threads)
assert any("OtelBatchSpanRecordProcessor" in name for name in threads), (
    "background worker not running; see scripts/check-worker.py docstring"
)
