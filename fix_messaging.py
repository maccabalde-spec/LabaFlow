path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ══════════════════════════════════════════════════════════════════════
# FIX 1: selectMsgCust — use DB.upsert per message instead of DB.set
# ══════════════════════════════════════════════════════════════════════
old1 = """function selectMsgCust(id){

  activeMsgCustId=id;

  const msgs=C.get('messages');

  msgs.filter(m=>m.fromId===id&&!m.read).forEach(m=>m.read=true);

  DB.set('messages',msgs);

  /* update sidebar badge */

  const totalUnread=msgs.filter(m=>!m.read&&m.toId!==id).length+msgs.filter(m=>m.fromId!==id&&!m.read).length;

  const badge=g('sb-msg-badge');

  if(badge){const cu=msgs.filter(m=>!m.read&&m.toId===CU.id).length;badge.textContent=cu;badge.style.display=cu?'':'none';}

  pgMessages();

}"""

new1 = """function selectMsgCust(id){

  activeMsgCustId=id;

  /* Mark messages from this customer as read — upsert each changed one */
  const msgs=C.get('messages');
  const toMark=msgs.filter(m=>m.fromId===id&&!m.read);
  toMark.forEach(m=>{m.read=true; DB.upsert('messages',m);});
  C.set('messages',msgs);

  /* Update sidebar badge */
  const badge=g('sb-msg-badge');
  if(badge){const cu=msgs.filter(m=>!m.read&&m.toId===CU.id).length;badge.textContent=cu;badge.style.display=cu?'':'none';}

  /* Re-render message panel */
  const mainEl=g('msgMain');
  if(mainEl) mainEl.innerHTML=renderMsgThread();
  const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;

}"""

if old1 in content:
    content = content.replace(old1, new1)
    count += 1
    print("✓ Fixed: selectMsgCust uses upsert per message")

# ══════════════════════════════════════════════════════════════════════
# FIX 2: refreshMsgUI — properly re-renders open thread when new msg arrives
# ══════════════════════════════════════════════════════════════════════
old2 = """function refreshMsgUI(){
  /* Re-render message list if messaging panel is open */
  if(typeof renderMsgList==='function') try{renderMsgList();}catch(e){}
  if(typeof updateMsgBadge==='function') try{updateMsgBadge();}catch(e){}
}"""

new2 = """function refreshMsgUI(){
  /* Update unread badge */
  if(typeof updateMsgBadge==='function') try{updateMsgBadge();}catch(e){}
  if(typeof updateSellerBell==='function') try{updateSellerBell();}catch(e){}

  /* Re-render message thread if seller messaging page is open */
  const mainEl=g('msgMain');
  if(mainEl&&activeMsgCustId){
    mainEl.innerHTML=renderMsgThread();
    const body=g('msgBody');if(body)body.scrollTop=body.scrollHeight;
  }

  /* Re-render customer message panel if open */
  const ptContent=g('ptContent');
  if(ptContent&&CU&&CU.role==='CUSTOMER'){
    /* Only refresh if message tab is visible */
    try{
      const msgBubbles=ptContent.querySelector('.msg-bubble,.msg-body');
      if(msgBubbles) ptMessages();
    }catch(e){}
  }

  /* Re-render seller customer list (unread counts) */
  if(mainEl&&typeof pgMessages==='function'){
    /* Refresh the customer list sidebar only */
    const msgList=document.querySelector('.msg-list');
    if(msgList){
      const users=C.get('users').filter(u=>u.role==='CUSTOMER');
      const msgs=C.get('messages');
      msgList.innerHTML=`
        <div style="padding:10px 13px;font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);">Customers</div>
        ${users.map(u=>{
          const thread=msgs.filter(m=>m.fromId===u.id||m.toId===u.id);
          const last=thread.length?thread[thread.length-1]:null;
          const unread=msgs.filter(m=>m.fromId===u.id&&!m.read).length;
          return \`<div class="msg-list-item\${activeMsgCustId===u.id?' active':''}" onclick="selectMsgCust(\${u.id})">
            \${unread?\`<span class="ml-unread">\${unread}</span>\`:''}
            <div class="ml-name">\${u.name}</div>
            <div class="ml-preview">\${last?last.text:'No messages yet'}</div>
          </div>\`;
        }).join('')||'<div class="empty" style="padding:20px;">No customers yet</div>'}
      `;
    }
  }
}"""

if old2 in content:
    content = content.replace(old2, new2)
    count += 1
    print("✓ Fixed: refreshMsgUI fully re-renders messages and customer list")

# ══════════════════════════════════════════════════════════════════════
# FIX 3: ptMessages mark-as-read — use upsert per message
# ══════════════════════════════════════════════════════════════════════
old3 = """  const allMsgs=C.get('messages');

  allMsgs.filter(m=>m.toId===CU.id&&!m.read).forEach(m=>m.read=true);

  DB.set('messages',allMsgs);

  updateMsgBadge();"""

new3 = """  /* Mark my messages as read — upsert only changed ones */
  const allMsgs=C.get('messages');
  const unreadMine=allMsgs.filter(m=>m.toId===CU.id&&!m.read);
  unreadMine.forEach(m=>{m.read=true; DB.upsert('messages',m);});
  C.set('messages',allMsgs);

  updateMsgBadge();"""

if old3 in content:
    content = content.replace(old3, new3)
    count += 1
    print("✓ Fixed: ptMessages mark-as-read uses upsert")

# ══════════════════════════════════════════════════════════════════════
# FIX 4: Customer send message — refresh UI immediately after send
# ══════════════════════════════════════════════════════════════════════
old4 = """  msgs.push(newMsg2);C.set('messages',msgs);DB.upsert('messages',newMsg2);input.value='';ptMessages();"""

new4 = """  msgs.push(newMsg2);C.set('messages',msgs);DB.upsert('messages',newMsg2);input.value='';
  /* Re-render immediately — real-time listener will also fire */
  ptMessages();"""

if old4 in content:
    content = content.replace(old4, new4)
    count += 1
    print("✓ Fixed: customer send message")

# ══════════════════════════════════════════════════════════════════════
# FIX 5: Notifications — add real-time Firestore listener for seller notifs
# ══════════════════════════════════════════════════════════════════════
# The current listener only watches notifs for current user (toId === CU.id)
# But seller needs to see order notifications too
# Fix: add separate listener for seller notifications

old5 = """  /* Reviews — real-time for landing page */
  _unsubListeners.push(DB.listen('reviews', data=>{
    _cache['reviews']=data;
    if(typeof renderLandingReviews==='function') try{renderLandingReviews(data);}catch(e){}
  }));"""

new5 = """  /* Reviews — real-time for landing page */
  _unsubListeners.push(DB.listen('reviews', data=>{
    _cache['reviews']=data;
    if(typeof renderLandingReviews==='function') try{renderLandingReviews(data);}catch(e){}
  }));

  /* All notifications — real-time (for seller seeing customer activity) */
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

if old5 in content:
    content = content.replace(old5, new5)
    count += 1
    print("✓ Fixed: real-time notification listener for all users")

# ══════════════════════════════════════════════════════════════════════
# FIX 6: updateNotifBadge — also update seller bell unread count
# ══════════════════════════════════════════════════════════════════════
old6 = """function updateNotifBadge(){

  const cnt=getUnreadCount();

  /* customer bell in nav */

  const bubble=g('custBellBubble');

  if(bubble){bubble.textContent=cnt;bubble.style.display=cnt?'':'none';}

}"""

new6 = """function updateNotifBadge(){

  const cnt=getUnreadCount();

  /* Customer bell bubble */
  const bubble=g('custBellBubble');
  if(bubble){bubble.textContent=cnt;bubble.style.display=cnt?'':'none';}

  /* Seller bell count */
  const sellerCnt=g('sellerBellCount');
  if(sellerCnt&&CU&&(CU.role==='SELLER'||CU.role==='ADMIN')){
    const sellerUnread=C.get('notifs').filter(n=>!n.read).length;
    sellerCnt.textContent=sellerUnread;
    sellerCnt.style.display=sellerUnread?'':'none';
  }

}"""

if old6 in content:
    content = content.replace(old6, new6)
    count += 1
    print("✓ Fixed: updateNotifBadge updates both customer and seller bells")

# ══════════════════════════════════════════════════════════════════════
# FIX 7: Fix broken placeholder and em-dash in msg input
# ══════════════════════════════════════════════════════════════════════
import re
# Fix corrupted placeholder
content = re.sub(
    r'placeholder="Type a message[^"]*"',
    'placeholder="Type a message..."',
    content
)
# Fix em-dash display in customer profile
content = content.replace(
    '${cust.email} \ufffd ${cust.phone||\'—\'}',
    '${cust.email} · ${cust.phone||\'—\'}'
)
content = content.replace(
    "${cust.email} \ufffd ${cust.phone||'\ufffd'}",
    "${cust.email} · ${cust.phone||'—'}"
)
count += 1
print("✓ Fixed: message input placeholder and em-dash")

# ══════════════════════════════════════════════════════════════════════
# FIX 8: markNotifRead — use upsert instead of set
# ══════════════════════════════════════════════════════════════════════
import re as re2

# Find markNotifRead / markCustNotifRead using DB.set
content = re2.sub(
    r"function markCustNotifRead\(id\)\{[^}]+\}",
    """function markCustNotifRead(id){
  const notifs=C.get('notifs');
  const n=notifs.find(x=>x.id===id);
  if(n){n.read=true;C.set('notifs',notifs);DB.upsert('notifs',n);}
  updateNotifBadge();
  renderCustNotifPanel();
}""",
    content
)
count += 1
print("✓ Fixed: markCustNotifRead uses upsert")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
