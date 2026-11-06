path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix 1: refreshMsgUI — correct the selector for ptMsgBody ─────────────
# The customer message body has id="ptMsgBody", not class="msg-body" inside ptContent
old1 = "  const ptMsgBody=document.querySelector('#ptContent .msg-body');"
new1 = "  const ptMsgBody=g('ptMsgBody');"
if old1 in content:
    content = content.replace(old1, new1)
    count += 1
    print("✓ Fixed: refreshMsgUI uses correct #ptMsgBody selector")

# ── Fix 2: ptMessages cache check — always reload when page opens ─────────
# C.has checks length > 0 but empty array returns false — we need always-fresh
old2 = """  /* Only fetch from Firestore if cache is empty (first open) */
  if(!C.has('messages')){
    const [freshUsers,freshMsgs]=await Promise.all([DB.get('users'),DB.get('messages')]);
    C.set('users',freshUsers); C.set('messages',freshMsgs);
  }"""
new2 = """  /* Always fetch fresh from Firestore when messages tab opens */
  const [freshUsers,freshMsgs]=await Promise.all([DB.get('users'),DB.get('messages')]);
  C.set('users',freshUsers); C.set('messages',freshMsgs);"""
if old2 in content:
    content = content.replace(old2, new2)
    count += 1
    print("✓ Fixed: ptMessages always loads fresh from Firestore")

# ── Fix 3: markAllCustNotifsRead — use upsert not DB.set ─────────────────
old3 = "  notifs.filter(n=>n.toId===CU.id).forEach(n=>n.read=true);\n\n  DB.set('notifs',notifs);renderCustNotifPanel();updateNotifBadge();"
new3 = """  const toMark=notifs.filter(n=>n.toId===CU.id&&!n.read);
  toMark.forEach(n=>{n.read=true;DB.upsert('notifs',n);});
  C.set('notifs',notifs);renderCustNotifPanel();updateNotifBadge();"""
if old3 in content:
    content = content.replace(old3, new3)
    count += 1
    print("✓ Fixed: markAllCustNotifsRead uses upsert")

# ── Fix 4: Notification panel heading broken symbol ──────────────────────
content = content.replace(
    '<h3 style="font-size:16px;font-weight:800;margin-bottom:16px;">?₱Notifications</h3>',
    '<h3 style="font-size:16px;font-weight:800;margin-bottom:16px;">🔔 Notifications</h3>'
)
count += 1
print("✓ Fixed: notification heading symbol")

# ── Fix 5: Mark-as-read in ptContent notifs (DB.set -> upsert) ───────────
old5 = "  all.filter(n=>n.toId===CU.id&&!n.read).forEach(n=>n.read=true);\n\n  DB.set('notifs',all);updateNotifBadge();"
new5 = """  const toMark2=all.filter(n=>n.toId===CU.id&&!n.read);
  toMark2.forEach(n=>{n.read=true;DB.upsert('notifs',n);});
  C.set('notifs',all);updateNotifBadge();"""
if old5 in content:
    content = content.replace(old5, new5)
    count += 1
    print("✓ Fixed: ptTab notifications mark-as-read uses upsert")

# ── Fix 6: Real-time notif listener — also refresh customer portal notif tab
old6 = """  /* All notifications — real-time (for seller seeing customer activity) */
  _unsubListeners.push(DB.listen('notifs', data=>{
    _cache['notifs']=data;
    if(typeof updateNotifBadge==='function') try{updateNotifBadge();}catch(e){}
    if(typeof updateSellerBell==='function') try{updateSellerBell();}catch(e){}
    if(typeof renderCustNotifPanel==='function'){
      const panel=g('custNotifPanel');
      if(panel&&panel.classList.contains('open')) try{renderCustNotifPanel();}catch(e){}
    }
    if(typeof renderNotifPanel==='function'){
      const panel=g('notifPanel');
      if(panel&&panel.classList.contains('open')) try{renderNotifPanel();}catch(e){}
    }
  }));"""

new6 = """  /* All notifications — real-time */
  _unsubListeners.push(DB.listen('notifs', data=>{
    _cache['notifs']=data;
    /* Update badges */
    try{updateNotifBadge();}catch(e){}
    try{updateSellerBell&&updateSellerBell();}catch(e){}
    /* Update open notification panels */
    try{
      const custPanel=g('custNotifPanel');
      if(custPanel&&custPanel.classList.contains('open')) renderCustNotifPanel();
    }catch(e){}
    try{
      const sellerPanel=g('notifPanel');
      if(sellerPanel&&sellerPanel.classList.contains('open')) renderNotifPanel&&renderNotifPanel();
    }catch(e){}
    /* Update customer portal notifications tab if open */
    try{
      if(CU&&CU.role==='CUSTOMER'&&curPtTab==='notifs'){
        const notifs=C.get('notifs').filter(n=>n.toId===CU.id).reverse();
        const ptContent=g('ptContent');
        if(ptContent){
          const list=ptContent.querySelector('.pt-notif-list,.empty');
          if(list){
            list.outerHTML=notifs.length
              ?'<div class="pt-notif-list">'+notifs.map(n=>
                '<div class="pt-notif-card'+(n.read?'':' unread')+'">'
                +'<span class="pt-notif-ico">'+n.icon+'</span>'
                +'<div class="pt-notif-body">'
                +'<div class="pt-notif-title">'+n.title+'</div>'
                +'<div class="pt-notif-msg">'+n.msg+'</div>'
                +'<div class="pt-notif-time">'+fs(n.date)+'</div>'
                +'</div></div>').join('')+'</div>'
              :'<div class="empty">No notifications yet</div>';
          }
        }
      }
    }catch(e){}
  }));"""

if old6 in content:
    content = content.replace(old6, new6)
    count += 1
    print("✓ Fixed: notification real-time listener updates portal notifs tab")

print(f"\nTotal: {count} web fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
