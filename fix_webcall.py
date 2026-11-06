path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix 1: startCall — actually launch the call ───────────────────────────
import re

# Find entire startCall function
fn_start = content.find('function startCall(name,type){')
fn_end   = content.find('\nfunction endCall(){')

if fn_start != -1 and fn_end != -1:
    old_fn = content[fn_start:fn_end]

    new_fn = '''function startCall(name,type){

  const SHOP_PHONE = '09615150075';

  /* -- Launch real call/video ------------------------------------------ */
  if(type==='audio'){
    /* Opens phone dialer on Android/iOS browsers */
    const a=document.createElement('a');
    a.href='tel:'+SHOP_PHONE;
    a.click();
  } else {
    /* Opens Google Meet in new tab for video */
    window.open('https://meet.google.com/new','_blank');
  }

  /* -- Also show the in-app overlay as a visual indicator --------------- */
  _callType=type;_callMuted=false;_callSecs=0;

  const av=g('callAvatar'),nm=g('callName'),st=g('callStatus'),vidBtn=g('callVidBtn');

  if(av)av.textContent=name[0].toUpperCase();

  if(nm)nm.textContent=name;

  if(st){
    st.textContent=type==='video'?'Opening Google Meet...':'Calling '+SHOP_PHONE+'...';
    st.classList.add('call-pulse');
  }

  if(vidBtn)vidBtn.style.display=type==='video'?'':'none';

  g('callOverlay').classList.add('active');

  /* After 2s show "Connected" */
  setTimeout(()=>{
    const st2=g('callStatus');
    if(st2){st2.textContent='Connected';st2.classList.remove('call-pulse');}

    _callTimer=setInterval(()=>{
      _callSecs++;
      const m=String(Math.floor(_callSecs/60)).padStart(2,'0');
      const s=String(_callSecs%60).padStart(2,'0');
      const timerEl=g('callTimer');if(timerEl)timerEl.textContent=`${m}:${s}`;
    },1000);

  },2000);
'''

    content = content[:fn_start] + new_fn + content[fn_end:]
    count += 1
    print("✓ Fixed: startCall launches real tel: / Google Meet + keeps overlay")

# ── Fix 2: Fix broken call status text (₱ corruption) ────────────────────
fixes = [
    ("st.textContent=type==='video'?'?₱Starting video call':'?₱Calling",
     "st.textContent=type==='video'?'📹 Starting video call...':'📞 Calling"),
    ("type==='video'?'?₱Starting video call':'?₱Calling",
     "type==='video'?'📹 Starting video call...':'📞 Calling"),
    ("'?₱Starting video call'", "'📹 Starting video call...'"),
    ("'?₱Calling'",             "'📞 Calling...'"),
]
for old, new in fixes:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"✓ Fixed: {repr(old[:60])}")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
