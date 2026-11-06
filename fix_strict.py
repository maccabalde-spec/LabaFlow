path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Remove 'use strict' from the data layer script block
# It causes DB (window.DB) to fail since DB is not declared in that scope
old = """<script>

'use strict';

/* --------------------------------------

   DATA LAYER"""

new = """<script>

/* DATA LAYER"""

if old in content:
    content = content.replace(old, new, 1)
    print("Fixed: removed 'use strict' from data layer script")
else:
    # Try finding it differently
    idx = content.find("'use strict';")
    if idx > 0:
        # Get context
        print(f"Found 'use strict' at index {idx}")
        print(repr(content[idx-50:idx+100]))
        # Remove just the use strict line
        content = content.replace("'use strict';\n\n", "", 1)
        print("Removed 'use strict'")
    else:
        print("'use strict' not found")

# Fix 2: Add const DB = window.DB alias at top of the data layer script
# So DB references work both with and without strict mode
old2 = """/* DB is already defined as window.DB in the Firebase module script above.
   This section just adds the ts() helper and runtime cache. */"""

new2 = """/* DB = window.DB alias so both 'DB.get(...)' and 'window.DB.get(...)' work */
const DB = (() => {
  // Wait for window.DB to be available (set by Firebase script above)
  return new Proxy({}, {
    get(_, prop) {
      if (!window.DB) {
        console.error('[LabaFlow] window.DB not ready yet. Firebase may still be loading.');
        if (prop === 'get') return async () => [];
        if (prop === 'set' || prop === 'upsert' || prop === 'del') return async () => {};
        if (prop === 'nextId') return async () => 1;
        if (prop === 'has') return async () => false;
        if (prop === 'listen' || prop === 'listenWhere') return () => () => {};
        return () => {};
      }
      const val = window.DB[prop];
      return typeof val === 'function' ? val.bind(window.DB) : val;
    }
  });
})();"""

if old2 in content:
    content = content.replace(old2, new2, 1)
    print("Fixed: added DB proxy alias")
else:
    print("WARNING: Could not find DB comment to add proxy")

# Fix 3: Also fix corrupted comment characters
content = content.replace('DATA LAYER \ufffd Firestore', 'DATA LAYER - Firestore')
content = content.replace('Async cache loader \ufffd call', 'Async cache loader - call')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
