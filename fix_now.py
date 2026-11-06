path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The ONLY change: remove the blocking loadAllCaches() before showing UI
# Move it to AFTER showing the UI (non-blocking)

old = '''  /* Load all Firestore data into cache before showing the UI */
  showLoader('Loading data\u25a0');
  await loadAllCaches();
  hideLoader();

  g('landing').style.display='none';

  document.body.classList.remove('lf-dark');

  const at=localStorage.getItem('lf_app_theme')||localStorage.getItem('lf_theme');

  if(at==='light')document.body.classList.add('lf-light');

  else document.body.classList.remove('lf-light');

  /* Start real-time listeners for live updates */
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

}'''

# Try to find it with the actual encoding in file
import re
# Find launchApp body
fn_start = content.find('async function launchApp(){')
fn_end   = content.find('\nfunction updateLoyaltyPill()')

if fn_start == -1 or fn_end == -1:
    print(f"ERROR: fn_start={fn_start} fn_end={fn_end}")
    exit(1)

print(f"Found launchApp from {fn_start} to {fn_end}")

new_fn = '''async function launchApp(){

  /* Show UI first — no waiting */
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

  /* Load Firestore data in background after UI is visible */
  loadAllCaches().then(function(){
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
  }).catch(function(e){
    console.warn('Data load error:', e);
    startRealtimeListeners();
  });

}
'''

content = content[:fn_start] + new_fn + content[fn_end:]
print(f"Replaced launchApp successfully")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
