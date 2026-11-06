path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ══════════════════════════════════════════════════════════════════════
# FIX 1: refreshMsgUI — only update DOM in-place, NEVER navigate
# ══════════════════════════════════════════════════════════════════════
import re

# Find and replace the entire refreshMsgUI function
old_fn1_start = 'function refreshMsgUI(){'
old_fn1_end   = '}\nfunction refreshOrderUI(){'

start = content.find(old_fn1_start)
end   = content.find(old_fn1_end)

if start != -1 and end != -1:
    old_block = content[start:end]
    new_block = '''function refreshMsgUI(){
  /* ── Update badges only ──────────────────────────────── */
  try{updateMsgBadge();}catch(e){}
  try{updateSellerBell&&updateSellerBell();}catch(e){}

  /* ── Seller: update open thread + customer list ─────── */
  const mainEl=g('msgMain');
  if(mainEl){
    /* Only update if messaging page is actually open (msgMain exists) */
    if(activeMsgCustId){
      /* Update thread bubbles in place */
      const bodyEl=g('msgBody');
      const msgThread=renderMsgThread();
      /* Update only the body part, not the whole thread (avoids losing input focus) */
      const tempDiv=document.createElement('div');
      tempDiv.innerHTML=msgThread;
      const newBody=tempDiv.querySelector('#msgBody');
      if(newBody&&bodyEl){
        bodyEl.innerHTML=newBody.innerHTML;
        bodyEl.scrollTop=bodyEl.scrollHeight;
      } else {
        /* fallback: full re-render */
        mainEl.innerHTML=msgThread;
        const b2=g('msgBody');if(b2)b2.scrollTop=b2.scrollHeight;
      }
    }
    /* Update customer list unread counts without full re-render */
    const msgList=document.querySelector('.msg-list');
    if(msgList){
      const users=C.get('users').filter(u=>u.role==='CUSTOMER');
      const msgs=C.get('messages');
      const listHTML=users.map(u=>{
        const thread=msgs.filter(m=>m.fromId===u.id||m.toId===u.id);
        const last=thread.length?thread[thread.length-1]:null;
        const unread=msgs.filter(m=>m.fromId===u.id&&!m.read).length;
        return '<div class="msg-list-item'+(activeMsgCustId===u.id?' active':'')+
          '" onclick="selectMsgCust('+u.id+')">'
          +(unread?'<span class="ml-unread">'+unread+'</span>':'')
          +'<div class="ml-name">'+u.name+'</div>'
          +'<div class="ml-preview">'+(last?last.text:'No messages yet')+'</div>'
          +'</div>';
      }).join('');
      msgList.innerHTML=
        '<div style="padding:10px 13px;font-size:11px;font-weight:700;'+
        'color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;'+
        'border-bottom:1px solid var(--border);">Customers</div>'
        +(listHTML||'<div class="empty" style="padding:20px;">No customers yet</div>');
    }
  }

  /* ── Customer portal: update message bubbles in place ── */
  const ptMsgBody=document.querySelector('#ptContent .msg-body');
  if(ptMsgBody&&CU&&CU.role==='CUSTOMER'){
    const msgs=C.get('messages').filter(m=>m.fromId===CU.id||m.toId===CU.id);
    if(msgs.length){
      const bubblesHTML=msgs.map(m=>{
        const mine=m.fromId===CU.id;
        const t=m.date?new Date(m.date).toLocaleTimeString('en-PH',{hour:'2-digit',minute:'2-digit'}):'';
        return '<div class="msg-bubble '+(mine?'msg-mine':'msg-theirs')+'">'+m.text+
          '<div class="msg-meta">'+t+'</div></div>';
      }).join('');
      ptMsgBody.innerHTML=bubblesHTML;
      ptMsgBody.scrollTop=ptMsgBody.scrollHeight;
    }
  }
}
function refreshOrderUI(){'''

    content = content[:start] + new_block + content[end + len('}\nfunction refreshOrderUI(){'):]
    count += 1
    print("✓ Fixed: refreshMsgUI no longer navigates")
else:
    print(f"NOT FOUND: refreshMsgUI block (start={start}, end={end})")

# ══════════════════════════════════════════════════════════════════════
# FIX 2: refreshOrderUI — do NOT call pgOrders (navigates to orders)
# Only update badge/alert, not the page content
# ══════════════════════════════════════════════════════════════════════
old2 = """function refreshOrderUI(){
  /* Re-render orders page if currently visible */
  const title=g('pgTitle');
  if(title&&(title.textContent.includes('Order')||title.textContent.includes('Dashboard'))){
    if(typeof pgOrders==='function') try{pgOrders();}catch(e){}
  }
}"""

new2 = """function refreshOrderUI(){
  /* Only update topbar low-stock alert — do NOT re-render page */
  try{checkTopbarAlerts&&checkTopbarAlerts();}catch(e){}
  /* Update sidebar order badge */
  try{updateSellerBell&&updateSellerBell();}catch(e){}
}"""

if old2 in content:
    content = content.replace(old2, new2)
    count += 1
    print("✓ Fixed: refreshOrderUI no longer navigates to orders page")

# ══════════════════════════════════════════════════════════════════════
# FIX 3: ptMessages — remove fresh DB.get fetch (causes full re-render)
# Instead only do fresh fetch on TAB OPEN, not on every message
# The real-time listener + refreshMsgUI handles live updates
# ══════════════════════════════════════════════════════════════════════
old3 = """async function ptMessages(){

  /* Reload fresh data from Firestore each time */
  const [freshUsers, freshMsgs] = await Promise.all([
    DB.get('users'), DB.get('messages')
  ]);
  C.set('users', freshUsers);
  C.set('messages', freshMsgs);

  const seller=C.get('users').find(u=>u.role==='SELLER'||u.role==='ADMIN');"""

new3 = """async function ptMessages(){

  /* Only fetch from Firestore if cache is empty (first open) */
  if(!C.has('messages')){
    const [freshUsers,freshMsgs]=await Promise.all([DB.get('users'),DB.get('messages')]);
    C.set('users',freshUsers); C.set('messages',freshMsgs);
  }

  const seller=C.get('users').find(u=>u.role==='SELLER'||u.role==='ADMIN');"""

if old3 in content:
    content = content.replace(old3, new3)
    count += 1
    print("✓ Fixed: ptMessages only fetches from Firestore on first open")

# ══════════════════════════════════════════════════════════════════════
# FIX 4: pgMessages — same, only fetch on first open
# ══════════════════════════════════════════════════════════════════════
old4 = """async function pgMessages(){

  /* Reload fresh data from Firestore each time page opens */
  const [freshUsers, freshMsgs] = await Promise.all([
    DB.get('users'), DB.get('messages')
  ]);
  C.set('users', freshUsers);
  C.set('messages', freshMsgs);

  const users=C.get('users').filter(u=>u.role==='CUSTOMER');"""

new4 = """async function pgMessages(){

  /* Fetch fresh from Firestore when page first opens */
  const [freshUsers,freshMsgs]=await Promise.all([DB.get('users'),DB.get('messages')]);
  C.set('users',freshUsers); C.set('messages',freshMsgs);

  const users=C.get('users').filter(u=>u.role==='CUSTOMER');"""

if old4 in content:
    content = content.replace(old4, new4)
    count += 1
    print("✓ Fixed: pgMessages still fetches fresh on page open")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
