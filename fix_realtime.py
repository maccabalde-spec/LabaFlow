path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace loadAllCaches + startRealtimeListeners block
# Find start marker
start_marker = 'async function loadAllCaches(){'
end_marker = '}\n\nfunction refreshMsgUI(){'

start_idx = content.find(start_marker)
end_idx   = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print(f"Markers not found! start={start_idx} end={end_idx}")
    # Debug
    idx = content.find('loadAllCaches')
    print(f"loadAllCaches at: {idx}")
    print(repr(content[idx-2:idx+50]))
    exit(1)

old_block = content[start_idx:end_idx]
print(f"Found block ({len(old_block)} chars), replacing...")

new_block = '''async function loadAllCaches(){
  /* Fetch all collections in PARALLEL for fast login */
  const cols=['users','inventory','rfidTags','orders','transactions',
              'messages','restockLog','promoCodes','notifs','reviews','settings'];
  const results = await Promise.all(cols.map(c => DB.get(c)));
  cols.forEach((c,i) => { _cache[c] = results[i]; });
}

/* Cache accessors (synchronous) */
const C = {
  get(k){ return _cache[k] || []; },
  set(k,v){ _cache[k]=v; },
  has(k){ return !!(_cache[k]&&_cache[k].length); },
  nextId(k){ const a=this.get(k); return a.length?Math.max(...a.map(x=>x.id))+1:1; },
};

function ts(daysAgo=0){const d=new Date();d.setDate(d.getDate()+daysAgo);return d.toISOString();}

/* Real-time listeners - all key collections stay in sync */
let _unsubListeners = [];

function stopRealtimeListeners(){
  _unsubListeners.forEach(fn => { try{ fn(); }catch(e){} });
  _unsubListeners = [];
}

function startRealtimeListeners(){
  if(!window.DB||!window.DB.listen) return;
  stopRealtimeListeners();

  _unsubListeners.push(DB.listen('orders', data=>{
    _cache['orders']=data; refreshOrderUI();
  }));

  _unsubListeners.push(DB.listen('messages', data=>{
    _cache['messages']=data; refreshMsgUI();
  }));

  _unsubListeners.push(DB.listen('inventory', data=>{
    _cache['inventory']=data;
    if(typeof checkTopbarAlerts==='function') try{checkTopbarAlerts();}catch(e){}
  }));

  _unsubListeners.push(DB.listen('users', data=>{
    _cache['users']=data;
    if(CU){
      const fresh=data.find(u=>u.id===CU.id);
      if(fresh){CU.points=fresh.points||0; sessionStorage.setItem('lf3_cu',JSON.stringify(CU));}
      if(typeof updateLoyaltyPill==='function') try{updateLoyaltyPill();}catch(e){}
    }
  }));

  _unsubListeners.push(DB.listen('transactions', data=>{
    _cache['transactions']=data;
  }));

  if(CU){
    _unsubListeners.push(DB.listenWhere('notifs','toId',CU.id, data=>{
      _cache['notifs']=data;
      if(typeof updateNotifBadge==='function') try{updateNotifBadge();}catch(e){}
      if(typeof updateSellerBell==='function') try{updateSellerBell();}catch(e){}
    }));
  }
}'''

content = content[:start_idx] + new_block + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done! loadAllCaches now parallel, real-time listeners expanded.")
