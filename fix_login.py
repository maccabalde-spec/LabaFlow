import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: doLogin — replace C.get('users') with DB.get('users') in the login block
# The issue is the global replacement turned DB.get -> C.get but login needs live Firestore data
content = content.replace(
    "const users = await C.get('users')",
    "const users = await DB.get('users')"
)

# Fix 2: doRegister — same issue
content = content.replace(
    "const users = await DB.get('users');\n\n  if(users.find(x=>x.email===email)){hideLoader();err.textContent='Email already registered.';err.style.display='block';return;}",
    "const users = await DB.get('users');\n\n  if(users.find(x=>x.email===email)){hideLoader();err.textContent='Email already registered.';err.style.display='block';return;}"
)

# Fix 3: _handleFirebaseUser — replace C.get('users') with DB.get('users')
content = content.replace(
    "const users = await C.get('users');\n  C.set('users', users);",
    "const users = await DB.get('users');\n  C.set('users', users);"
)

# Fix 4: loadAllCaches — all C.get() inside it should be DB.get() since it fetches fresh data
# Find loadAllCaches function and fix it
old_load = "async function loadAllCaches(){\n  const cols=['users','inventory','rfidTags','orders','transactions',\n              'messages','restockLog','promoCodes','notifs','reviews','settings'];\n  for(const c of cols){\n    _cache[c] = await C.get(c);\n  }\n}"
new_load = "async function loadAllCaches(){\n  const cols=['users','inventory','rfidTags','orders','transactions',\n              'messages','restockLog','promoCodes','notifs','reviews','settings'];\n  for(const c of cols){\n    _cache[c] = await DB.get(c);\n  }\n}"
content = content.replace(old_load, new_load)

# Also fix any remaining await C.get( patterns (these should all be DB.get for async calls)
content = re.sub(r'await C\.get\(', 'await DB.get(', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed! Counts:")
print(f"  DB.get occurrences: {content.count('DB.get(')}")
print(f"  C.get occurrences (sync): {content.count('C.get(')}")
print(f"  await DB.get: {content.count('await DB.get(')}")
