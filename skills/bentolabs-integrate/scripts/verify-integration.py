"""Step 5a (integration path): confirm bento.instrument() activated.

Used when Step 3 Path A was taken. Expects `activated` to be "adk". If
it is None, the [adk] extra is not installed. Run `pip install
"bentolabs-sdk[adk]"` in the same venv this script uses.

After `activated` prints, invoke one real ADK agent run and confirm a
span lands in the dashboard.
"""

import bentolabs_sdk as bento

bento.init()
activated = bento.instrument()
print(f"activated: {activated!r}")

# ...invoke one ADK agent run here...

bento.flush()
