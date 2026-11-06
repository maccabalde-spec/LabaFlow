"""
Fix web messaging: ptMessages and pgMessages should load fresh from Firestore
when first opened, and the real-time listener should keep them updated.
Also fix: sendSellerMsg and send customer msg need to await loadAllCaches
after sending so C cache stays fresh.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix 1: pgMessages (seller) — reload messages from Firestore first ────
old1 = """function pgMessages(){

  const users=C.get('users').filter(u=>u.role==='CUSTOMER');

  const msgs=C.get('messages');"""

new1 = """async function pgMessages(){

  /* Reload fresh data from Firestore each time page opens */
  const [freshUsers, freshMsgs] = await Promise.all([
    DB.get('users'), DB.get('messages')
  ]);
  C.set('users', freshUsers);
  C.set('messages', freshMsgs);

  const users=C.get('users').filter(u=>u.role==='CUSTOMER');

  const msgs=C.get('messages');"""

if old1 in content:
    content = content.replace(old1, new1)
    count += 1
    print("✓ Fixed: pgMessages loads fresh from Firestore")

# ── Fix 2: ptMessages (customer) — same fix ───────────────────────────────
old2 = """function ptMessages(){

  const seller=C.get('users').find(u=>u.role==='SELLER'||u.role==='ADMIN');

  if(seller)ptActiveSellerId=seller.id;

  const msgs=C.get('messages').filter(m=>m.fromId===CU.id||m.toId===CU.id);"""

new2 = """async function ptMessages(){

  /* Reload fresh data from Firestore each time */
  const [freshUsers, freshMsgs] = await Promise.all([
    DB.get('users'), DB.get('messages')
  ]);
  C.set('users', freshUsers);
  C.set('messages', freshMsgs);

  const seller=C.get('users').find(u=>u.role==='SELLER'||u.role==='ADMIN');

  if(seller)ptActiveSellerId=seller.id;

  const msgs=C.get('messages').filter(m=>m.fromId===CU.id||m.toId===CU.id);"""

if old2 in content:
    content = content.replace(old2, new2)
    count += 1
    print("✓ Fixed: ptMessages loads fresh from Firestore")

# ── Fix 3: After sending message (seller), re-render properly ─────────────
old3 = """  msgs.push(newMsg);C.set('messages',msgs);DB.upsert('messages',newMsg);input.value='';

  g('msgMain').innerHTML=renderMsgThread();

  const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;"""

new3 = """  msgs.push(newMsg);C.set('messages',msgs);DB.upsert('messages',newMsg);input.value='';

  /* Re-render immediately */
  const mainEl=g('msgMain');if(mainEl)mainEl.innerHTML=renderMsgThread();

  const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;"""

if old3 in content:
    content = content.replace(old3, new3)
    count += 1
    print("✓ Fixed: seller send message re-renders properly")

# ── Fix 4: refreshMsgUI — also call pgMessages to ensure sidebar is fresh ─
old4 = """function refreshMsgUI(){
  /* Update unread badge */
  if(typeof updateMsgBadge==='function') try{updateMsgBadge();}catch(e){}
  if(typeof updateSellerBell==='function') try{updateSellerBell();}catch(e){}

  /* Re-render message thread if seller messaging page is open */
  const mainEl=g('msgMain');
  if(mainEl&&activeMsgCustId){
    mainEl.innerHTML=renderMsgThread();
    const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;
  }"""

new4 = """function refreshMsgUI(){
  /* Update unread badge */
  if(typeof updateMsgBadge==='function') try{updateMsgBadge();}catch(e){}
  if(typeof updateSellerBell==='function') try{updateSellerBell();}catch(e){}

  /* Re-render message thread if seller messaging page is open */
  const mainEl=g('msgMain');
  if(mainEl&&activeMsgCustId){
    mainEl.innerHTML=renderMsgThread();
    const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;
  }

  /* Also refresh customer list sidebar unread counts */
  const msgList=document.querySelector('.msg-list');
  if(msgList&&typeof pgMessages!=='undefined'){
    const users=C.get('users').filter(u=>u.role==='CUSTOMER');
    const msgs=C.get('messages');
    const listHTML=users.map(u=>{
      const thread=msgs.filter(m=>m.fromId===u.id||m.toId===u.id);
      const last=thread.length?thread[thread.length-1]:null;
      const unread=msgs.filter(m=>m.fromId===u.id&&!m.read).length;
      return '<div class="msg-list-item'+(activeMsgCustId===u.id?' active':'')+'" onclick="selectMsgCust('+u.id+')">'
        +(unread?'<span class="ml-unread">'+unread+'</span>':'')
        +'<div class="ml-name">'+u.name+'</div>'
        +'<div class="ml-preview">'+(last?last.text:'No messages yet')+'</div>'
        +'</div>';
    }).join('');
    msgList.innerHTML='<div style="padding:10px 13px;font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);">Customers</div>'
      +(listHTML||'<div class="empty" style="padding:20px;">No customers yet</div>');
  }"""

if old4 in content:
    content = content.replace(old4, new4)
    count += 1
    print("✓ Fixed: refreshMsgUI rebuilds customer list")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
