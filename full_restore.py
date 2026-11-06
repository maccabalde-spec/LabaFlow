"""
Full restore: bring back the ORIGINAL working launchApp and auto-login.
Remove _waitForDB completely - it's causing the blank page.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# ══════════════════════════════════════════════════════════
# Step 1: Replace entire launchApp with the ORIGINAL working version
# ══════════════════════════════════════════════════════════
fn_start = content.find('async function launchApp(){')
fn_end   = content.find('\nfunction updateLoyaltyPill()')

ORIGINAL_LAUNCH = '''async function launchApp(){

  g('landing').style.display='none';

  document.body.classList.remove('lf-dark');

  const at=localStorage.getItem('lf_app_theme')||localStorage.getItem('lf_theme');

  if(at==='light')document.body.classList.add('lf-light');

  else document.body.classList.remove('lf-light');

  startRealtimeListeners();

  if(CU.role==='CUSTOMER'){

    g('portal').style.display='block';

    g('ptUserName').textContent=CU.name;

    updateLoyaltyPill();

    updateMsgBadge();

    updateNotifBadge();

    ptTab('orders');

  } else {

    g('app').style.display='block';

    g('sbName').textContent=CU.name;

    g('sbRole').textContent=CU.role==='ADMIN'?'Administrator':'Seller / Staff';

    g('sbAv').textContent=CU.name[0].toUpperCase();

    g('pgDate').textContent=new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric',year:'numeric'});

    buildSidebar();

    checkTopbarAlerts();

    updateSellerBell();

    refreshSidebarAvatar();

    showPage(CU.role==='ADMIN'?'dashboard':'orders');

  }

}

'''

if fn_start != -1 and fn_end != -1:
    content = content[:fn_start] + ORIGINAL_LAUNCH + content[fn_end:]
    print("✓ Restored original launchApp")

# ══════════════════════════════════════════════════════════
# Step 2: Restore original auto-login (remove _waitForDB)
# ══════════════════════════════════════════════════════════

# Remove everything from "/* Wait for Firebase" to end of file's auto-login block
wait_start = content.find('/* Wait for Firebase/Firestore to initialize before auto-login */')
saved_start = content.find('const savedCU=sessionStorage.getItem')

if wait_start != -1 and saved_start != -1 and wait_start < saved_start:
    # Remove the _waitForDB function definition
    content = content[:wait_start] + content[saved_start:]
    print("✓ Removed _waitForDB function")

# Fix the auto-login to use simple direct call
old_login = """if(savedCU){
  try{
    CU=JSON.parse(savedCU);
    _waitForDB(()=>{ launchApp(); });
  }catch(e){ console.error('Auto-login error:', e); }
}"""

new_login = "if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}catch(e){}}"

if old_login in content:
    content = content.replace(old_login, new_login)
    print("✓ Restored simple auto-login")
else:
    # Try to find and fix any variant
    content = re.sub(
        r'if\(savedCU\)\{[^}]*_waitForDB[^}]*\}',
        "if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}catch(e){}}",
        content, flags=re.DOTALL
    )
    print("✓ Fixed auto-login via regex")

# ══════════════════════════════════════════════════════════
# Step 3: Also restore loadAllCaches to load AFTER showing UI
#         (so page shows immediately, data loads in background)
# ══════════════════════════════════════════════════════════
# The original launchApp above doesn't call loadAllCaches at all
# The real-time listeners (startRealtimeListeners) will populate data
# But we need to also call loadAllCaches for initial data
# Let's add it non-blocking AFTER showing the page

LAUNCH_WITH_CACHE = '''async function launchApp(){

  g('landing').style.display='none';

  document.body.classList.remove('lf-dark');

  const at=localStorage.getItem('lf_app_theme')||localStorage.getItem('lf_theme');

  if(at==='light')document.body.classList.add('lf-light');

  else document.body.classList.remove('lf-light');

  if(CU.role==='CUSTOMER'){

    g('portal').style.display='block';

    g('ptUserName').textContent=CU.name;

    ptTab('orders');

  } else {

    g('app').style.display='block';

    g('sbName').textContent=CU.name;

    g('sbRole').textContent=CU.role==='ADMIN'?'Administrator':'Seller / Staff';

    g('sbAv').textContent=CU.name[0].toUpperCase();

    g('pgDate').textContent=new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric',year:'numeric'});

    buildSidebar();

    showPage(CU.role==='ADMIN'?'dashboard':'orders');

  }

  /* Load data and refresh UI */
  loadAllCaches().then(()=>{
    startRealtimeListeners();
    if(CU.role==='CUSTOMER'){
      updateLoyaltyPill();
      updateMsgBadge();
      updateNotifBadge();
    } else {
      checkTopbarAlerts();
      updateSellerBell();
      refreshSidebarAvatar();
      showPage(CU.role==='ADMIN'?'dashboard':'orders');
    }
  }).catch(()=>{
    startRealtimeListeners();
  });

}

'''

# Replace the restored launchApp with this better version
fn_start2 = content.find('async function launchApp(){')
fn_end2   = content.find('\nfunction updateLoyaltyPill()')
if fn_start2 != -1 and fn_end2 != -1:
    content = content[:fn_start2] + LAUNCH_WITH_CACHE + content[fn_end2:]
    print("✓ Updated launchApp: show UI first, load data in background")

# ══════════════════════════════════════════════════════════
# Step 4: Remove ALL broken CSS injections
# ══════════════════════════════════════════════════════════
broken_css = [
    # Nunito font import
    ("@import url('https://fonts.googleapis.com/css2?family=Nunito", "/* Nunito removed */"),
    # body inline style
    ('<body style="background:#f0f9ff;">', '<body>'),
    ('<body style="background: #f0f9ff;">', '<body>'),
]
for old, new in broken_css:
    if old in content:
        content = content.replace(old, new)
        print(f"✓ Fixed: {old[:50]!r}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\nFile size: {len(content)}")
print("✅ Done!")
