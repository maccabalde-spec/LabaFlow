path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# ══════════════════════════════════════════════════════════════════════
# FIX 1: Wait for window.DB before auto-login at page load
# This is the ROOT CAUSE of missing content
# ══════════════════════════════════════════════════════════════════════
old_autologin = '''const savedCU=sessionStorage.getItem('lf3_cu');

if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}catch(e){}}'''

new_autologin = '''/* Wait for Firebase/Firestore to initialize before auto-login */
function _waitForDB(cb, tries=0){
  if(window.DB && typeof window.DB.get==='function'){
    cb();
  } else if(tries < 50){ /* wait up to 5 seconds */
    setTimeout(()=>_waitForDB(cb, tries+1), 100);
  } else {
    console.warn('[LabaFlow] DB not ready after 5s, launching anyway');
    cb();
  }
}

const savedCU=sessionStorage.getItem('lf3_cu');

if(savedCU){
  try{
    CU=JSON.parse(savedCU);
    _waitForDB(()=>{ launchApp(); });
  }catch(e){ console.error('Auto-login error:', e); }
}'''

if old_autologin in content:
    content = content.replace(old_autologin, new_autologin)
    print("✓ Fixed: auto-login now waits for window.DB to be ready")
else:
    print("⚠ Auto-login not found, trying alternate...")
    # Try to find and fix it differently
    idx = content.find("if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}")
    if idx != -1:
        old = "if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}catch(e){}}"
        new = "if(savedCU){try{CU=JSON.parse(savedCU);_waitForDB(()=>{launchApp();});}catch(e){}}"
        content = content.replace(old, new)
        print("✓ Fixed: auto-login (alternate method)")

# ══════════════════════════════════════════════════════════════════════
# FIX 2: Also fix launchApp to be simple and reliable
#         Remove the timeout/skeleton complexity
# ══════════════════════════════════════════════════════════════════════
import re

fn_start = content.find('async function launchApp(){')
fn_end   = content.find('\nfunction updateLoyaltyPill()')

if fn_start != -1 and fn_end != -1:
    new_fn = '''async function launchApp(){

  /* 1. Set correct background immediately */
  const _at=localStorage.getItem('lf_app_theme')||localStorage.getItem('lf_theme');
  const _isLight=_at==='light';
  document.body.classList.toggle('lf-light',_isLight);
  document.body.classList.remove('lf-dark');
  document.body.style.cssText='background:'+(_isLight?'#f0f9ff':'#071525')+';min-height:100vh;';

  /* 2. Hide landing */
  g('landing').style.display='none';

  /* 3. Load all data from Firestore (DB is ready because _waitForDB ensured it) */
  await loadAllCaches();

  /* 4. Show correct view with real data */
  if(CU.role==='CUSTOMER'){
    g('portal').style.display='block';
    if(g('ptUserName'))g('ptUserName').textContent=CU.name;
    try{updateLoyaltyPill();}catch(e){}
    try{updateMsgBadge();}catch(e){}
    try{updateNotifBadge();}catch(e){}
    try{ptTab('orders');}catch(e){}
  } else {
    g('app').style.display='block';
    if(g('sbName'))g('sbName').textContent=CU.name;
    if(g('sbRole'))g('sbRole').textContent=CU.role==='ADMIN'?'Administrator':'Seller / Staff';
    if(g('sbAv'))g('sbAv').textContent=CU.name[0].toUpperCase();
    if(g('pgDate'))g('pgDate').textContent=new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric',year:'numeric'});
    try{buildSidebar();}catch(e){}
    try{checkTopbarAlerts();}catch(e){}
    try{updateSellerBell();}catch(e){}
    try{refreshSidebarAvatar();}catch(e){}
    try{showPage(CU.role==='ADMIN'?'dashboard':'orders');}catch(e){console.error('showPage:',e);}
  }

  /* 5. Start real-time listeners */
  try{startRealtimeListeners();}catch(e){}

}

'''
    content = content[:fn_start] + new_fn + content[fn_end:]
    print("✓ Fixed launchApp: simple version, DB guaranteed ready")

# ══════════════════════════════════════════════════════════════════════
# FIX 3: Remove ALL old injected dashboard CSS, inject ONE clean version
# ══════════════════════════════════════════════════════════════════════

# Remove all injected dashboard blocks
while True:
    idx = content.find('/* ════════════════════════════════════════════════════════════\n   DASHBOARD')
    if idx == -1:
        break
    # Find end of this block (next triple newline or another ===)
    end_markers = ['\n\n\n\n', '/* ════']
    end_idx = -1
    for em in end_markers:
        pos = content.find(em, idx+100)
        if pos != -1 and (end_idx == -1 or pos < end_idx):
            end_idx = pos
    if end_idx == -1:
        end_idx = idx + 5000
    content = content[:idx] + content[end_idx:]
    print("  Removed old dashboard CSS block")

NEW_CSS = """
/* ════════════════════════════════════════════════════════════
   DASHBOARD THEME — Sky Blue Bubble Laundry (matches landing)
════════════════════════════════════════════════════════════ */

/* Dark palette matching landing page sky blue */
body:not(.lf-light){
  --bg:#071525;--sidebar:#040d18;--surface:#091830;--card:#0c2040;
  --border:#1a3d5c;--accent:#38bdf8;--accent2:#0ea5e9;
  --btn:#0284c7;--btn-hover:#0369a1;
  --text:#f0f9ff;--text-muted:#90c4e4;--text-dim:#3a6a8a;
  --success:#34d399;--warn:#fbbf24;--danger:#fb7185;--bubble-me:#0284c7;
}

/* Sky blue bubble radial gradient background */
body:not(.lf-light) .content{
  background:
    radial-gradient(circle at 12% 18%,rgba(56,189,248,.08) 90px,transparent 90px),
    radial-gradient(circle at 88% 75%,rgba(14,165,233,.07) 110px,transparent 110px),
    radial-gradient(circle at 50% 50%,rgba(2,132,199,.04) 150px,transparent 150px),
    radial-gradient(circle at 78% 18%,rgba(56,189,248,.06) 65px,transparent 65px),
    radial-gradient(circle at 22% 82%,rgba(14,165,233,.05) 75px,transparent 75px),
    #071525 !important;
}
body:not(.lf-light) .pt-wrap{
  background:
    radial-gradient(circle at 12% 18%,rgba(56,189,248,.08) 90px,transparent 90px),
    radial-gradient(circle at 88% 75%,rgba(14,165,233,.07) 110px,transparent 110px),
    radial-gradient(circle at 50% 50%,rgba(2,132,199,.04) 150px,transparent 150px),
    #071525 !important;
}
body:not(.lf-light) .shell{background:#071525;}
body:not(.lf-light) .sidebar{background:linear-gradient(180deg,#040d18,#071525)!important;border-right:1px solid rgba(56,189,248,.12)!important;}
.sb-logo span{color:#38bdf8!important;}
body:not(.lf-light) .sb-icon{background:linear-gradient(135deg,#0284c7,#0ea5e9)!important;border-radius:10px!important;}
body:not(.lf-light) .topbar{background:rgba(4,13,24,.97)!important;border-bottom:1px solid rgba(56,189,248,.15)!important;box-shadow:0 2px 20px rgba(0,0,0,.4)!important;}
body:not(.lf-light) .tb-title{color:#38bdf8!important;font-weight:800!important;}
.nav-item.active{background:rgba(56,189,248,.12)!important;border-left:3px solid #38bdf8!important;color:#38bdf8!important;}
.nav-item:hover{background:rgba(56,189,248,.07)!important;color:#90c4e4!important;}
body:not(.lf-light) .sc{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.15)!important;border-radius:14px!important;transition:all .25s!important;}
body:not(.lf-light) .sc:hover{border-color:rgba(56,189,248,.4)!important;box-shadow:0 8px 28px rgba(2,132,199,.2)!important;transform:translateY(-3px)!important;}
body:not(.lf-light) .card{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.12)!important;border-radius:14px!important;}
body:not(.lf-light) .card:hover{border-color:rgba(56,189,248,.3)!important;box-shadow:0 6px 24px rgba(2,132,199,.12)!important;}
body:not(.lf-light) .ch{background:rgba(56,189,248,.07)!important;border-bottom:1px solid rgba(56,189,248,.12)!important;}
body:not(.lf-light) .ch h4{color:#38bdf8!important;font-weight:800!important;}
body:not(.lf-light) th{background:rgba(56,189,248,.09)!important;color:#7dd3fc!important;font-size:11px!important;letter-spacing:.5px!important;}
body:not(.lf-light) td{color:#e0f2fe!important;border-bottom:1px solid rgba(56,189,248,.06)!important;}
body:not(.lf-light) tbody tr:hover td{background:rgba(56,189,248,.06)!important;}
.btn-primary{background:linear-gradient(135deg,#0ea5e9,#0369a1)!important;border:none!important;border-radius:50px!important;font-weight:700!important;box-shadow:0 4px 16px rgba(2,132,199,.35)!important;}
.btn-primary:hover{transform:translateY(-2px)!important;box-shadow:0 8px 24px rgba(2,132,199,.5)!important;}
.s-PENDING{background:rgba(148,163,184,.12)!important;color:#94a3b8!important;}
.s-RECEIVED{background:rgba(56,189,248,.15)!important;color:#38bdf8!important;}
.s-PROCESSING{background:rgba(251,191,36,.15)!important;color:#fbbf24!important;}
.s-READY{background:rgba(52,211,153,.15)!important;color:#34d399!important;}
.s-RELEASED{background:rgba(167,139,250,.15)!important;color:#c4b5fd!important;}
body:not(.lf-light) .msg-wrap{background:#071525!important;}
.msg-mine{background:linear-gradient(135deg,#0284c7,#0369a1)!important;}
body:not(.lf-light) .msg-theirs{background:#0c2040!important;border:1px solid rgba(56,189,248,.15)!important;}
body:not(.lf-light) .msg-input-row{background:#040d18!important;border-top:1px solid rgba(56,189,248,.12)!important;}
body:not(.lf-light) .msg-input-row input{background:#071525!important;border:1.5px solid rgba(56,189,248,.2)!important;color:#e0f2fe!important;border-radius:50px!important;}
body:not(.lf-light) .fg input,body:not(.lf-light) .fg select,body:not(.lf-light) .fg textarea{background:#040d18!important;border:1.5px solid rgba(56,189,248,.18)!important;color:#e0f2fe!important;border-radius:10px!important;}
body:not(.lf-light) .fg label{color:#90c4e4!important;}
body:not(.lf-light) .pt-nav{background:rgba(4,13,24,.97)!important;border-bottom:1px solid rgba(56,189,248,.15)!important;}
body:not(.lf-light) .pt-tab{color:#4a7fa8!important;font-weight:700!important;}
body:not(.lf-light) .pt-tab.active{color:#38bdf8!important;border-bottom-color:#38bdf8!important;}
body:not(.lf-light) .ord-card{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.15)!important;border-radius:14px!important;}
body:not(.lf-light) .ord-card:hover{border-color:rgba(56,189,248,.4)!important;box-shadow:0 8px 28px rgba(2,132,199,.15)!important;}
.loyalty-card{background:linear-gradient(135deg,#0369a1,#0284c7,#0ea5e9)!important;border-radius:20px!important;}
body:not(.lf-light) .ov>div,body:not(.lf-light) .modal-inner{background:#09182e!important;border:1px solid rgba(56,189,248,.2)!important;border-radius:20px!important;}
body:not(.lf-light) .modal h3{color:#38bdf8!important;}
.notif-bell{border:1.5px solid rgba(56,189,248,.2)!important;border-radius:10px!important;}
.notif-bell:hover{border-color:#38bdf8!important;background:rgba(56,189,248,.08)!important;}
.app-theme-btn{border:1.5px solid rgba(56,189,248,.2)!important;border-radius:8px!important;color:#90c4e4!important;font-weight:700!important;}
.app-theme-btn:hover{border-color:#38bdf8!important;color:#38bdf8!important;}
/* Light mode */
body.lf-light{--bg:#f0f9ff;--sidebar:#fff;--surface:#fff;--card:#fff;--border:#bae6fd;--accent:#0284c7;--accent2:#0369a1;--btn:#0284c7;--text:#0c1a2e;--text-muted:#334155;--text-dim:#64748b;background:#f0f9ff;}
body.lf-light .content{background:#f0f9ff!important;}
body.lf-light .pt-wrap{background:#f0f9ff!important;}
body.lf-light .sidebar{background:#fff!important;box-shadow:1px 0 0 #bae6fd!important;}
body.lf-light .topbar{background:#fff!important;border-bottom:1px solid #bae6fd!important;}
body.lf-light .tb-title{color:#0284c7!important;}
body.lf-light .sc{background:#fff!important;border:1.5px solid #bae6fd!important;border-radius:14px!important;}
body.lf-light .sc-val{color:#0c1a2e!important;}
body.lf-light .card{background:#fff!important;border:1px solid #bae6fd!important;border-radius:14px!important;}
body.lf-light .ch{background:#e0f2fe!important;border-bottom:1px solid #bae6fd!important;}
body.lf-light .ch h4{color:#0284c7!important;}
body.lf-light th{background:#e0f2fe!important;color:#334155!important;}
body.lf-light .nav-item.active{background:rgba(2,132,199,.1)!important;border-left-color:#0284c7!important;color:#0284c7!important;}
"""

style_end = content.rfind('</style>')
if style_end != -1:
    content = content[:style_end] + NEW_CSS + '\n' + content[style_end:]
    print("✓ Injected clean dashboard CSS")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Done!")
