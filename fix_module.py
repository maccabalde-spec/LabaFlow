path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the entire module script block
start = content.find('<!-- -- FIREBASE -- -->\n<script type="module">')
if start == -1:
    start = content.find('<!-- ══ FIREBASE ══ -->\n<script type="module">')
if start == -1:
    # Try finding just the module script
    start = content.find('<script type="module">')
    
end = content.find('</script>', start) + len('</script>')

print(f"Found module script at {start}-{end}")
old_module = content[start:end]

# Replace with non-module script using Firebase compat CDN
new_script = '''<!-- ══ FIREBASE ══ -->
<!-- Use compat CDN (no ES modules) so onclick handlers work -->
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore-compat.js"></script>
<script>
  /* ── FIREBASE CONFIG ───────────────────────────────────────────────── */
  const firebaseConfig = {
    apiKey:            "AIzaSyCn5QBSkNYVAcPSLHwByl9okW-UcUhT4EE",
    authDomain:        "labaflow-71e13.firebaseapp.com",
    projectId:         "labaflow-71e13",
    storageBucket:     "labaflow-71e13.firebasestorage.app",
    messagingSenderId: "598387534227",
    appId:             "1:598387534227:web:fc1d40bf72cee5d959a066",
    measurementId:     "G-T6YJ6NRMFR"
  };

  firebase.initializeApp(firebaseConfig);

  const fbAuth  = firebase.auth();
  const fbStore = firebase.firestore();

  /* expose Auth helpers to global scope */
  window._fbAuth    = fbAuth;
  window._gProvider = new firebase.auth.GoogleAuthProvider();
  window._signInWithPopup  = (auth, provider) => auth.signInWithPopup(provider);
  window._signOut          = (auth) => auth.signOut();

  /* ── FIRESTORE DB HELPER ────────────────────────────────────────────
     Path: labaflow/data/{collection}/{docId}
     Compatible with Flutter app's FirestoreService.
  ─────────────────────────────────────────────────────────────────── */
  window.DB = {
    _col(name) {
      return fbStore.collection('labaflow').doc('data').collection(name);
    },

    async get(colName) {
      try {
        const snap = await this._col(colName).orderBy('id').get();
        return snap.docs.map(d => d.data());
      } catch(e) { console.error('DB.get', colName, e); return []; }
    },

    async set(colName, items) {
      try {
        const ref  = this._col(colName);
        const snap = await ref.get();
        /* delete existing in batches */
        for(let i=0;i<snap.docs.length;i+=490){
          const b = fbStore.batch();
          snap.docs.slice(i,i+490).forEach(d => b.delete(d.ref));
          await b.commit();
        }
        /* write new items in batches */
        for(let i=0;i<items.length;i+=490){
          const b = fbStore.batch();
          items.slice(i,i+490).forEach(item => {
            b.set(ref.doc(String(item.id)), item);
          });
          await b.commit();
        }
      } catch(e) { console.error('DB.set', colName, e); }
    },

    async upsert(colName, item) {
      try {
        await this._col(colName).doc(String(item.id)).set(item, {merge:true});
      } catch(e) { console.error('DB.upsert', colName, e); }
    },

    async del(colName, id) {
      try {
        await this._col(colName).doc(String(id)).delete();
      } catch(e) { console.error('DB.del', colName, e); }
    },

    async nextId(colName) {
      try {
        const snap = await this._col(colName).orderBy('id','desc').limit(1).get();
        if(snap.empty) return 1;
        return ((snap.docs[0].data().id) || 0) + 1;
      } catch(e) { return 1; }
    },

    async has(colName) {
      try {
        const snap = await this._col(colName).limit(1).get();
        return !snap.empty;
      } catch(e) { return false; }
    },

    listen(colName, callback) {
      return this._col(colName).orderBy('id').onSnapshot(snap => {
        callback(snap.docs.map(d => d.data()));
      }, err => console.error('DB.listen', colName, err));
    },

    listenWhere(colName, field, value, callback) {
      return this._col(colName)
        .where(field,'==',value)
        .orderBy('id')
        .onSnapshot(snap => {
          callback(snap.docs.map(d => d.data()));
        }, err => console.error('DB.listenWhere', colName, err));
    },
  };

  /* ── SEED ──────────────────────────────────────────────────────────── */
  (async function seedFirestore(){
    const hasUsers = await window.DB.has('users');
    if(hasUsers) return;

    function ts(daysAgo=0){const d=new Date();d.setDate(d.getDate()+daysAgo);return d.toISOString();}

    await window.DB.set('users',[
      {id:1,name:'Administrator', email:'admin@labaday.com', phone:'09171234567',role:'ADMIN',  pass:'password123',points:0},
      {id:2,name:'Seller Staff',  email:'seller@labaday.com',phone:'09181234567',role:'SELLER', pass:'password123',points:0},
      {id:3,name:'Juan dela Cruz',email:'juan@gmail.com',    phone:'09191234567',role:'CUSTOMER',pass:'password123',points:370},
      {id:4,name:'Maria Santos',  email:'maria@gmail.com',   phone:'09201234567',role:'CUSTOMER',pass:'password123',points:590},
    ]);
    await window.DB.set('inventory',[
      {id:1,name:'Surf Liquid Detergent',  cat:'DETERGENT',unit:'L',qty:12.5,thresh:1.0, packSize:2.5,packQty:5,perLoad:0.1, perKg:0},
      {id:2,name:'Surf Fabric Conditioner',cat:'SOFTENER', unit:'L',qty:8.0, thresh:0.8, packSize:1.6,packQty:5,perLoad:0.1, perKg:0},
      {id:3,name:'Zonrox Color Safe',      cat:'BLEACH',   unit:'L',qty:4.5, thresh:0.45,packSize:0.9,packQty:5,perLoad:0.01,perKg:0},
    ]);
    const tags=[];for(let i=1;i<=10;i++)tags.push({id:i,uid:`TAG-${String(i).padStart(3,'0')}`,available:true,orderId:null});
    await window.DB.set('rfidTags',tags);
    await window.DB.set('orders',[
      {id:1,num:'ORD-001',custId:3,custName:'Juan dela Cruz',tagId:null,type:'CLOTHES',  kg:5,   comQty:null,status:'PENDING',   notes:'',price:180,breakdown:'P180 base (7kg)', discount:0,promoCode:'',finalPrice:null,dropOff:null,   ready:null,pickup:null,created:ts(-3)},
      {id:2,num:'ORD-002',custId:4,custName:'Maria Santos',  tagId:2,   type:'BEDSHEET', kg:5,   comQty:null,status:'RECEIVED',  notes:'',price:190,breakdown:'P190 base (5kg)', discount:0,promoCode:'',finalPrice:null,dropOff:ts(-2), ready:null,pickup:null,created:ts(-2)},
      {id:3,num:'ORD-003',custId:3,custName:'Juan dela Cruz',tagId:3,   type:'CLOTHES',  kg:8,   comQty:null,status:'PROCESSING',notes:'Separate whites',price:255,breakdown:'P180 + 3kg extra x P25',discount:0,promoCode:'',finalPrice:null,dropOff:ts(-1),ready:null,pickup:null,created:ts(-1)},
      {id:4,num:'ORD-004',custId:4,custName:'Maria Santos',  tagId:4,   type:'COMFORTER',kg:null,comQty:2,  status:'READY',     notes:'',price:400,breakdown:'2 comforters x P200',discount:0,promoCode:'',finalPrice:400, dropOff:ts(-1),ready:new Date().toISOString(),pickup:null,created:ts(-1)},
    ]);
    const updTags=tags.map(t=>{
      if(t.id===2)return{...t,available:false,orderId:2};
      if(t.id===3)return{...t,available:false,orderId:3};
      if(t.id===4)return{...t,available:false,orderId:4};
      return t;
    });
    await window.DB.set('rfidTags',updTags);
    await window.DB.set('promoCodes',[
      {id:1,code:'WELCOME',disc:10,maxUses:100,uses:0,desc:'Welcome discount',active:true},
      {id:2,code:'LABA20', disc:20,maxUses:30, uses:0,desc:'Special promo',   active:true},
    ]);
    await fbStore.collection('labaflow').doc('data').collection('settings').doc('gcashNumber').set({key:'gcashNumber',val:'09615150075'});
    for(const col of ['transactions','messages','restockLog','notifs','reviews']){
      await window.DB.set(col,[]);
    }
    console.log('[LabaFlow] Firestore seeded!');
  })();

  /* ── Auth state watcher ─────────────────────────────────────────────── */
  fbAuth.onAuthStateChanged(async (firebaseUser) => {
    if (firebaseUser && !sessionStorage.getItem('lf3_cu')) {
      if(typeof window._handleFirebaseUser === 'function'){
        window._handleFirebaseUser(firebaseUser);
      }
    } else if (firebaseUser && sessionStorage.getItem('lf3_cu')) {
      try {
        const cu = JSON.parse(sessionStorage.getItem('lf3_cu'));
        if (cu._googleUid === firebaseUser.uid) {
          cu.name        = firebaseUser.displayName || cu.name;
          cu.googlePhoto = firebaseUser.photoURL    || cu.googlePhoto;
          sessionStorage.setItem('lf3_cu', JSON.stringify(cu));
          await window.DB.upsert('users', cu);
        }
      } catch(e) {}
    } else if (!firebaseUser) {
      const raw = sessionStorage.getItem('lf3_cu');
      if (raw) {
        try {
          if (JSON.parse(raw)._googleUid) {
            sessionStorage.removeItem('lf3_cu');
            window.CU = null;
          }
        } catch(e) {}
      }
    }
  });
</script>'''

content = content[:start] + new_script + content[end:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Done! Replaced {len(old_module)} chars with {len(new_script)} chars")
print("Switched from type=module to compat CDN - onclick handlers will now work!")
