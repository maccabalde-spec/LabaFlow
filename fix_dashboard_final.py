"""
Fix:
1. Dashboard content gone — showPage() called before data in cache, so pages render empty
2. Dashboard background needs sky blue bubble/laundry theme
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# ══════════════════════════════════════════════════════════════════════
# FIX 1: launchApp — DON'T call showPage() before data loads
#         Show a loading skeleton first, then show real page
# ══════════════════════════════════════════════════════════════════════

fn_start = content.find('async function launchApp(){')
fn_end   = content.find('\nfunction updateLoyaltyPill()')

if fn_start != -1 and fn_end != -1:
    new_fn = '''async function launchApp(){

  /* ── Step 1: Set background IMMEDIATELY (no white flash) ── */
  const _at=localStorage.getItem('lf_app_theme')||localStorage.getItem('lf_theme');
  if(_at==='light'){
    document.body.classList.add('lf-light');
    document.body.style.backgroundColor='#f0f9ff';
  } else {
    document.body.classList.remove('lf-dark');
    document.body.classList.remove('lf-light');
    document.body.style.backgroundColor='#071525';
  }

  /* ── Step 2: Hide landing immediately ── */
  g('landing').style.display='none';

  /* ── Step 3: Show skeleton loader while Firestore loads ── */
  if(CU.role==='CUSTOMER'){
    g('portal').style.display='block';
    if(g('ptUserName'))g('ptUserName').textContent=CU.name;
    /* Show skeleton tabs but wait for data */
    const ptContent=g('ptContent');
    if(ptContent)ptContent.innerHTML=`
      <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:300px;gap:16px;">
        <div style="width:44px;height:44px;border:3px solid rgba(56,189,248,.2);border-top-color:#38bdf8;border-radius:50%;animation:spin .7s linear infinite;"></div>
        <div style="color:#90c4e4;font-size:14px;font-weight:600;">Loading your data...</div>
      </div>`;
  } else {
    g('app').style.display='block';
    if(g('sbName'))g('sbName').textContent=CU.name;
    if(g('sbRole'))g('sbRole').textContent=CU.role==='ADMIN'?'Administrator':'Seller / Staff';
    if(g('sbAv'))g('sbAv').textContent=CU.name[0].toUpperCase();
    if(g('pgDate'))g('pgDate').textContent=new Date().toLocaleDateString('en-PH',{weekday:'short',month:'short',day:'numeric',year:'numeric'});
    try{buildSidebar();}catch(e){}
    /* Show skeleton in main content area */
    const pgContent=g('pgContent');
    if(pgContent)pgContent.innerHTML=`
      <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:400px;gap:16px;">
        <div style="width:44px;height:44px;border:3px solid rgba(56,189,248,.2);border-top-color:#38bdf8;border-radius:50%;animation:spin .7s linear infinite;"></div>
        <div style="color:#90c4e4;font-size:14px;font-weight:600;">Loading dashboard...</div>
      </div>`;
  }

  /* ── Step 4: Load Firestore data, THEN render real content ── */
  try {
    await loadAllCaches();
  } catch(e) {
    console.warn('[LabaFlow] Cache load error:', e);
  }

  /* ── Step 5: Now render the real UI with actual data ── */
  startRealtimeListeners();

  if(CU.role==='CUSTOMER'){
    try{updateLoyaltyPill();}catch(e){}
    try{updateMsgBadge();}catch(e){}
    try{updateNotifBadge();}catch(e){}
    try{ptTab('orders');}catch(e){}
  } else {
    try{checkTopbarAlerts();}catch(e){}
    try{updateSellerBell();}catch(e){}
    try{refreshSidebarAvatar();}catch(e){}
    try{showPage(CU.role==='ADMIN'?'dashboard':'orders');}catch(e){}
  }

}

'''
    content = content[:fn_start] + new_fn + content[fn_end:]
    print("✓ Fixed launchApp: skeleton UI + proper data load order")

# ══════════════════════════════════════════════════════════════════════
# FIX 2: Dashboard sky blue bubble background theme
#         Replace the old dark palette CSS with sky blue laundry theme
# ══════════════════════════════════════════════════════════════════════

DASHBOARD_BG_CSS = """

/* ════════════════════════════════════════════════════════════
   DASHBOARD SKY BLUE LAUNDRY BUBBLE THEME
   Matches the landing page sky blue / white / bubble palette
════════════════════════════════════════════════════════════ */

/* ── App background with bubble pattern ── */
body:not(.lf-light) {
  --bg:        #071525;
  --sidebar:   #040d18;
  --surface:   #09182e;
  --card:      #0c2040;
  --border:    #1a3d5c;
  --accent:    #38bdf8;
  --accent2:   #0ea5e9;
  --btn:       #0284c7;
  --btn-hover: #0369a1;
  --text:      #f0f9ff;
  --text-muted:#90c4e4;
  --text-dim:  #3a6a8a;
  --success:   #34d399;
  --warn:      #fbbf24;
  --danger:    #fb7185;
  --bubble-me: #0284c7;
}

/* ── Main content area — sky blue bubble background ── */
body:not(.lf-light) .content,
body:not(.lf-light) #pgContent,
body:not(.lf-light) .main-area {
  background:
    radial-gradient(circle at 10% 20%,  rgba(14,165,233,.08) 80px, transparent 80px),
    radial-gradient(circle at 90% 70%,  rgba(56,189,248,.06) 120px, transparent 120px),
    radial-gradient(circle at 50% 50%,  rgba(2,132,199,.04)  200px, transparent 200px),
    radial-gradient(circle at 20% 80%,  rgba(14,165,233,.05) 60px, transparent 60px),
    radial-gradient(circle at 80% 10%,  rgba(56,189,248,.07) 90px, transparent 90px),
    #071525;
}

/* ── Sidebar with gradient ── */
body:not(.lf-light) .sidebar {
  background: linear-gradient(180deg, #040d18 0%, #071525 60%, #050f1e 100%);
  border-right: 1px solid rgba(56,189,248,.12);
}

/* ── Customer portal background ── */
body:not(.lf-light) .pt-wrap {
  background:
    radial-gradient(circle at 15% 25%, rgba(14,165,233,.08) 100px, transparent 100px),
    radial-gradient(circle at 85% 75%, rgba(56,189,248,.06) 140px, transparent 140px),
    radial-gradient(circle at 50% 10%, rgba(2,132,199,.05)  80px, transparent 80px),
    #071525;
}

/* ── Shell and main areas ── */
body:not(.lf-light) .shell { background: #071525; }

/* ── Topbar ── */
body:not(.lf-light) .topbar {
  background: rgba(4,13,24,.95);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(56,189,248,.12);
  box-shadow: 0 2px 16px rgba(0,0,0,.3);
}
body:not(.lf-light) .tb-title { color: #38bdf8 !important; font-weight: 800; }

/* ── Nav items ── */
.nav-item.active {
  background: linear-gradient(90deg, rgba(56,189,248,.15), rgba(56,189,248,.05)) !important;
  border-left: 3px solid #38bdf8 !important;
  color: #38bdf8 !important;
}
.nav-item:hover {
  background: rgba(56,189,248,.08) !important;
  color: #90c4e4 !important;
}
.sb-logo span { color: #38bdf8 !important; }

/* ── Stat cards ── */
body:not(.lf-light) .sc {
  background: linear-gradient(135deg, #0c2040, #091830);
  border: 1px solid rgba(56,189,248,.15);
  border-radius: 16px;
  transition: all .25s;
  position: relative; overflow: hidden;
}
body:not(.lf-light) .sc::before {
  content: ''; position: absolute;
  top: -30px; right: -30px;
  width: 80px; height: 80px; border-radius: 50%;
  background: rgba(56,189,248,.06); pointer-events: none;
}
body:not(.lf-light) .sc:hover {
  border-color: rgba(56,189,248,.35);
  box-shadow: 0 8px 28px rgba(2,132,199,.18);
  transform: translateY(-2px);
}
body:not(.lf-light) .sc-val { color: #f0f9ff; font-weight: 900; }
body:not(.lf-light) .sc-lbl { color: #90c4e4; }

/* ── Cards ── */
body:not(.lf-light) .card {
  background: linear-gradient(135deg, #0c2040, #09182e);
  border: 1px solid rgba(56,189,248,.12);
  border-radius: 16px;
  transition: border-color .2s, box-shadow .2s;
}
body:not(.lf-light) .card:hover {
  border-color: rgba(56,189,248,.28);
  box-shadow: 0 6px 24px rgba(2,132,199,.12);
}
body:not(.lf-light) .ch {
  background: rgba(56,189,248,.06);
  border-bottom: 1px solid rgba(56,189,248,.12);
  padding: 13px 16px;
}
body:not(.lf-light) .ch h4 { color: #38bdf8 !important; font-weight: 800; }

/* ── Tables ── */
body:not(.lf-light) th {
  background: rgba(56,189,248,.08) !important;
  color: #7dd3fc !important;
  font-weight: 800 !important;
  border-bottom: 1px solid rgba(56,189,248,.15) !important;
  text-transform: uppercase;
  letter-spacing: .5px;
  font-size: 11px !important;
}
body:not(.lf-light) td {
  color: #e0f2fe;
  border-bottom: 1px solid rgba(56,189,248,.06) !important;
}
body:not(.lf-light) tbody tr:hover td {
  background: rgba(56,189,248,.06) !important;
}

/* ── Buttons ── */
body:not(.lf-light) .btn-primary {
  background: linear-gradient(135deg, #0ea5e9, #0369a1) !important;
  border: none !important;
  border-radius: 50px !important;
  font-weight: 700 !important;
  box-shadow: 0 4px 16px rgba(2,132,199,.35) !important;
  transition: all .2s !important;
}
body:not(.lf-light) .btn-primary:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 8px 24px rgba(2,132,199,.5) !important;
}

/* ── Badges ── */
.b-blue { background: rgba(56,189,248,.15) !important; color: #38bdf8 !important; border-radius: 6px; }
.b-green { background: rgba(52,211,153,.15) !important; color: #34d399 !important; }
.b-yellow { background: rgba(251,191,36,.15) !important; color: #fbbf24 !important; }
.b-red { background: rgba(251,113,133,.15) !important; color: #fb7185 !important; }
.s-PENDING    { background: rgba(148,163,184,.12) !important; color: #94a3b8 !important; }
.s-RECEIVED   { background: rgba(56,189,248,.15) !important; color: #38bdf8 !important; }
.s-PROCESSING { background: rgba(251,191,36,.15) !important; color: #fbbf24 !important; }
.s-READY      { background: rgba(52,211,153,.15) !important; color: #34d399 !important; }
.s-RELEASED   { background: rgba(167,139,250,.15) !important; color: #c4b5fd !important; }

/* ── Customer portal tabs ── */
body:not(.lf-light) .pt-nav {
  background: rgba(4,13,24,.95) !important;
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(56,189,248,.15) !important;
}
body:not(.lf-light) .pt-tab { color: #4a7fa8 !important; font-weight: 700; }
body:not(.lf-light) .pt-tab.active {
  color: #38bdf8 !important;
  border-bottom: 2px solid #38bdf8 !important;
}
body:not(.lf-light) .pt-tab:hover { color: #90c4e4 !important; }

/* ── Order cards ── */
body:not(.lf-light) .ord-card {
  background: linear-gradient(135deg, #0c2040, #09182e) !important;
  border: 1px solid rgba(56,189,248,.15) !important;
  border-radius: 16px !important;
  transition: all .25s !important;
}
body:not(.lf-light) .ord-card:hover {
  border-color: rgba(56,189,248,.4) !important;
  box-shadow: 0 8px 28px rgba(2,132,199,.15) !important;
  transform: translateY(-2px) !important;
}

/* ── Loyalty card ── */
.loyalty-card {
  background: linear-gradient(135deg, #0369a1, #0284c7, #0ea5e9) !important;
  border-radius: 20px !important;
  box-shadow: 0 12px 40px rgba(2,132,199,.45) !important;
}

/* ── Messages ── */
body:not(.lf-light) .msg-wrap { background: #071525 !important; }
body:not(.lf-light) .msg-list-item:hover,
body:not(.lf-light) .msg-list-item.active {
  background: rgba(56,189,248,.08) !important;
}
.msg-mine { background: linear-gradient(135deg, #0284c7, #0369a1) !important; }
body:not(.lf-light) .msg-theirs {
  background: #0c2040 !important;
  border: 1px solid rgba(56,189,248,.15) !important;
}
body:not(.lf-light) .msg-input-row input {
  background: #040d18 !important;
  border: 1.5px solid rgba(56,189,248,.2) !important;
  color: #e0f2fe !important;
  border-radius: 50px !important;
}
body:not(.lf-light) .msg-input-row input:focus {
  border-color: #38bdf8 !important;
  box-shadow: 0 0 0 3px rgba(56,189,248,.12) !important;
}

/* ── Forms in dashboard ── */
body:not(.lf-light) .fg input,
body:not(.lf-light) .fg select,
body:not(.lf-light) .fg textarea {
  background: #040d18 !important;
  border: 1.5px solid rgba(56,189,248,.18) !important;
  color: #e0f2fe !important;
  border-radius: 10px !important;
}
body:not(.lf-light) .fg input:focus,
body:not(.lf-light) .fg select:focus {
  border-color: #38bdf8 !important;
  box-shadow: 0 0 0 3px rgba(56,189,248,.12) !important;
}
body:not(.lf-light) .fg label { color: #90c4e4 !important; }

/* ── Modals ── */
body:not(.lf-light) .ov > div,
body:not(.lf-light) .modal-inner {
  background: #09182e !important;
  border: 1px solid rgba(56,189,248,.2) !important;
  border-radius: 20px !important;
}
body:not(.lf-light) .modal h3 { color: #38bdf8 !important; font-weight: 900 !important; }

/* ── Notification bell ── */
.notif-bell {
  border: 1.5px solid rgba(56,189,248,.2) !important;
  border-radius: 10px !important;
}
.notif-bell:hover {
  border-color: #38bdf8 !important;
  background: rgba(56,189,248,.08) !important;
}
.notif-bubble { background: #0284c7 !important; }

/* ── Sidebar brand ── */
body:not(.lf-light) .sb-brand {
  border-bottom: 1px solid rgba(56,189,248,.12) !important;
}
body:not(.lf-light) .sb-icon {
  background: linear-gradient(135deg, #0284c7, #0ea5e9) !important;
}

/* ── App theme button ── */
.app-theme-btn {
  border: 1.5px solid rgba(56,189,248,.2) !important;
  border-radius: 8px !important;
  color: #90c4e4 !important;
  font-weight: 700 !important;
}
.app-theme-btn:hover {
  border-color: #38bdf8 !important;
  color: #38bdf8 !important;
  background: rgba(56,189,248,.08) !important;
}

/* ── Light mode dashboard ── */
body.lf-light {
  --bg:#f0f9ff; --sidebar:#ffffff; --surface:#ffffff; --card:#ffffff;
  --border:#bae6fd; --accent:#0284c7; --accent2:#0369a1;
  --btn:#0284c7; --btn-hover:#0369a1;
  --text:#0c1a2e; --text-muted:#334155; --text-dim:#64748b;
}
body.lf-light .content,
body.lf-light #pgContent { background: #f0f9ff; }
body.lf-light .sidebar { background: #fff; box-shadow: 1px 0 0 #bae6fd; }
body.lf-light .topbar { background: #fff; border-bottom: 1px solid #bae6fd; }
body.lf-light .tb-title { color: #0284c7 !important; }
body.lf-light .sc { background: #fff; border: 1.5px solid #bae6fd; border-radius: 16px; }
body.lf-light .sc-val { color: #0c1a2e; font-weight: 900; }
body.lf-light .card { background: #fff; border: 1px solid #bae6fd; border-radius: 16px; }
body.lf-light .ch { background: #e0f2fe; border-bottom: 1px solid #bae6fd; }
body.lf-light .ch h4 { color: #0284c7 !important; }
body.lf-light th { background: #e0f2fe !important; color: #334155 !important; }
body.lf-light .nav-item.active { background: rgba(2,132,199,.1) !important; border-left-color: #0284c7 !important; color: #0284c7 !important; }
body.lf-light .pt-wrap { background: #f0f9ff; }
"""

# Find the last </style> and inject
style_end = content.rfind('</style>')
if style_end != -1:
    content = content[:style_end] + DASHBOARD_BG_CSS + '\n' + content[style_end:]
    print("✓ Injected dashboard sky blue theme CSS")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Done!")
