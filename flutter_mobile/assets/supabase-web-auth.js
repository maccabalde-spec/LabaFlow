/* Public-key Supabase bridge for the standalone LabaFlow web client. */
(function (global) {
  'use strict';
  const config = global.LABAFLOW_SUPABASE_CONFIG || {};
  const sessionKey = 'labaflow.supabase.session.v1';
  const pkceVerifierKey = 'labaflow.supabase.pkce.verifier.v1';
  const base = () => String(config.url || '').replace(/\/$/, '');
  const key = () => config.publishableKey || '';
  function configured() { return /^https:\/\//.test(base()) && key().startsWith('sb_publishable_'); }
  function requireConfig() { if (!configured()) throw new Error('Supabase is not configured. Check supabase-config.js.'); }
  function session() { try { return JSON.parse(localStorage.getItem(sessionKey) || 'null'); } catch (_) { return null; } }
  function save(s) { localStorage.setItem(sessionKey, JSON.stringify(s)); }
  function signOut() { localStorage.removeItem(sessionKey); localStorage.removeItem('lf3_cu'); }
  async function refreshSession() {
    const old = session();
    if (!old?.refresh_token) return null;
    const response = await fetch(`${base()}/auth/v1/token?grant_type=refresh_token`, {
      method:'POST', headers:{apikey:key(),'Content-Type':'application/json'},
      body:JSON.stringify({refresh_token:old.refresh_token}),
    });
    const next = await response.json().catch(()=>null);
    if (!response.ok || !next?.access_token) { signOut(); return null; }
    save(next); return next;
  }
  async function request(path, options = {}, auth = true) {
    requireConfig();
    const s = session();
    const headers = {'apikey': key(), 'Content-Type': 'application/json', ...(options.headers || {})};
    if (auth && s?.access_token) headers.Authorization = `Bearer ${s.access_token}`;
    let response = await fetch(`${base()}${path}`, {...options, headers});
    if (response.status === 401 && auth && s?.refresh_token) {
      const next = await refreshSession();
      if (next) response = await fetch(`${base()}${path}`, {...options, headers:{...headers,Authorization:`Bearer ${next.access_token}`}});
    }
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.msg || data.message || data.error_description || data.error || data.details || `Supabase request failed (${response.status}).`);
    return data;
  }
  function profile(row, authUser = {}) { const providers=authUser.app_metadata?.providers || []; return {id:Number(row.public_id || 0), authUid:row.id, name:row.full_name || 'Customer', email:row.email || '', phone:row.phone || '', role:String(row.role || 'CUSTOMER').toUpperCase(), points:Number(row.points || 0), pic:row.avatar_url || null, googleConnected:providers.includes('google')}; }
  async function profileByUid(uid) {
    const [rows, authUser] = await Promise.all([
      request(`/rest/v1/profiles?id=eq.${encodeURIComponent(uid)}&select=*`),
      request('/auth/v1/user'),
    ]);
    if (!rows.length) throw new Error('Supabase profile is missing. Check the database migration.');
    const row=rows[0], metadata=authUser.user_metadata || {};
    const googleName=metadata.full_name || metadata.name || '';
    const googlePhoto=metadata.avatar_url || metadata.picture || '';
    const changes={};
    const profileName=String(row.full_name || '');
    const emailPrefix=String(authUser.email || '').split('@')[0];
    if ((!profileName || profileName === 'Customer' || profileName === emailPrefix) && googleName) changes.full_name=googleName;
    if (!row.avatar_url && googlePhoto) changes.avatar_url=googlePhoto;
    if (Object.keys(changes).length) {
      await request(`/rest/v1/profiles?id=eq.${encodeURIComponent(uid)}`,{method:'PATCH',headers:{Prefer:'return=minimal'},body:JSON.stringify(changes)});
      Object.assign(row,changes);
    }
    return profile(row, authUser);
  }
  function normPhone10(v) {
    const d = String(v || '').replace(/\D/g, '');
    return d.length >= 10 ? d.slice(-10) : '';
  }
  function normPhone11(v) {
    const p10 = normPhone10(v);
    return p10 ? '0' + p10 : '';
  }
  function getLocalPhoneMap() {
    try { return JSON.parse(localStorage.getItem('lf3_phone_lookup') || '[]'); } catch (_) { return []; }
  }
  function saveLocalPhoneMap(list) {
    try { localStorage.setItem('lf3_phone_lookup', JSON.stringify(list)); } catch (_) {}
  }
  async function syncPhoneEntry(phone, email) {
    const p11 = normPhone11(phone), em = String(email || '').trim().toLowerCase();
    if (!p11 || !em.includes('@')) return;
    let items = getLocalPhoneMap();
    const p10 = normPhone10(p11);
    items = items.filter(x => normPhone10(x.phone) !== p10 && String(x.email || '').toLowerCase() !== em);
    items.push({ phone: p11, email: em });
    saveLocalPhoneMap(items);
    if (!configured() || !session()?.access_token) return;
    try {
      const rows = await request('/rest/v1/app_collections?key=eq.phoneLookup&select=items', {}, false);
      const remote = Array.isArray(rows?.[0]?.items) ? rows[0].items : [];
      const merged = [...remote.filter(x => normPhone10(x.phone) !== p10 && String(x.email || '').toLowerCase() !== em), { phone: p11, email: em }];
      saveLocalPhoneMap(merged);
      await saveCollection('phoneLookup', merged);
    } catch (_) {}
  }
  async function emailForPhone(phone) {
    const p10 = normPhone10(phone);
    if (!p10) return null;
    try {
      const rpcEmail = await request('/rest/v1/rpc/login_email_for_phone', {method:'POST', body:JSON.stringify({p_phone:normPhone11(phone)})}, false);
      if (typeof rpcEmail === 'string' && rpcEmail.includes('@')) return rpcEmail.trim().toLowerCase();
    } catch (_) {}
    try {
      const rows = await request('/rest/v1/app_collections?key=eq.phoneLookup&select=items', {}, false);
      const remote = Array.isArray(rows?.[0]?.items) ? rows[0].items : [];
      if (remote.length) saveLocalPhoneMap(remote);
      const hit = remote.find(x => normPhone10(x.phone) === p10);
      if (hit?.email) return String(hit.email).trim().toLowerCase();
    } catch (_) {}
    const localHit = getLocalPhoneMap().find(x => normPhone10(x.phone) === p10);
    if (localHit?.email) return String(localHit.email).trim().toLowerCase();
    try {
      const cachedUsers = JSON.parse(localStorage.getItem('lf3_users') || '[]');
      const uHit = cachedUsers.find(u => normPhone10(u.phone) === p10 && u.email);
      if (uHit?.email) return String(uHit.email).trim().toLowerCase();
    } catch (_) {}
    const defaults = [
      { phone: '09611308218', email: 'seller@labaday.com' },
      { phone: '09171234567', email: 'juan@gmail.com' },
      { phone: '09181234567', email: 'maria@gmail.com' },
      { phone: '09170000001', email: 'admin@labaday.com' }
    ];
    const defHit = defaults.find(d => normPhone10(d.phone) === p10);
    return defHit ? defHit.email : ('0' + p10 + '@phone.labaflow.local');
  }
  async function phoneRegistered(phone) {
    try { return !!(await emailForPhone(phone)); } catch (_) { return false; }
  }
  async function signIn(identifier, password) {
    let email = String(identifier || '').trim().toLowerCase();
    if (!email.includes('@')) {
      const found = await emailForPhone(email);
      if (!found) throw new Error('Walang nahanap na account gamit ang mobile number na iyan. Mag-register muna o gamitin ang iyong email.');
      email = found.trim().toLowerCase();
    }
    const result = await request('/auth/v1/token?grant_type=password', {method:'POST', body:JSON.stringify({email, password})}, false);
    save(result);
    const prof = await profileByUid(result.user.id);
    if (prof?.phone && prof?.email) syncPhoneEntry(prof.phone, prof.email);
    return prof;
  }
  async function register({name,email,phone,password}) {
    const cleanPhone = normPhone11(phone || '');
    const cleanEmail = String(email || '').trim().toLowerCase() || (cleanPhone ? `${cleanPhone}@phone.labaflow.local` : '');
    const result = await request('/auth/v1/signup', {method:'POST', body:JSON.stringify({email:cleanEmail,password,data:{name:name.trim(),phone:cleanPhone}})}, false);
    if (!result.access_token || !result.user) throw new Error('Account created. Confirm your email, then sign in.');
    save(result);
    const prof = await profileByUid(result.user.id);
    if (cleanPhone) await syncPhoneEntry(cleanPhone, cleanEmail);
    return prof;
  }
  function base64Url(bytes) {
    let binary = '';
    bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  }
  async function createPkcePair() {
    const bytes = new Uint8Array(64);
    crypto.getRandomValues(bytes);
    const verifier = base64Url(bytes);
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
    return {verifier, challenge:base64Url(new Uint8Array(digest))};
  }
  async function signInWithGoogle() {
    requireConfig();
    let ref=location;
    try{ if(window.top && window.top!==window && window.top.location.origin===location.origin) ref=window.top.location; }catch(e){}
    const redirectTo=`${ref.origin}${ref.pathname.replace(/[^/]*\.html$/,'')}`;
    const {verifier,challenge}=await createPkcePair();
    localStorage.setItem(pkceVerifierKey,verifier);
    const authorize=new URL(`${base()}/auth/v1/authorize`);
    authorize.searchParams.set('provider','google');
    authorize.searchParams.set('redirect_to',redirectTo);
    authorize.searchParams.set('prompt','select_account');
    authorize.searchParams.set('code_challenge',challenge);
    authorize.searchParams.set('code_challenge_method','s256');
    if (window.top && window.top !== window) window.top.location.assign(authorize.toString());
    else location.assign(authorize.toString());
  }
  async function completeGoogleRedirect() {
    const query=new URLSearchParams(location.search);
    const oauthError=query.get('error_description') || query.get('error');
    if (oauthError) {
      history.replaceState(null,'',location.pathname);
      throw new Error(`Google sign-in could not be completed: ${oauthError}`);
    }
    const code=query.get('code');
    if(code){
      const verifier=localStorage.getItem(pkceVerifierKey);
      if(!verifier)throw new Error('Google sign-in could not be completed. Please start sign-in again in this browser.');
      const tokens=await request('/auth/v1/token?grant_type=pkce',{
        method:'POST',body:JSON.stringify({auth_code:code,code_verifier:verifier}),
      },false);
      save(tokens);
      localStorage.removeItem(pkceVerifierKey);
      query.delete('code');
      query.delete('sb_flow_id');
      const remainingQuery=query.toString();
      history.replaceState(null,'',`${location.pathname}${remainingQuery?`?${remainingQuery}`:''}${location.hash}`);
      return;
    }
    if (!location.hash.includes('access_token=')) return;
    const params=new URLSearchParams(location.hash.slice(1));
    const accessToken=params.get('access_token'), refreshToken=params.get('refresh_token');
    if (!accessToken || !refreshToken) return;
    save({access_token:accessToken,refresh_token:refreshToken,token_type:params.get('token_type')||'bearer',expires_in:Number(params.get('expires_in')||3600),expires_at:Math.floor(Date.now()/1000)+Number(params.get('expires_in')||3600)});
    localStorage.removeItem(pkceVerifierKey);
    history.replaceState(null,'',location.pathname);
  }
  async function restore() { const s=session(); if (!s?.access_token) return null; const data=await request('/auth/v1/user'); return profileByUid(data.id); }
  async function updateProfile(user, {name,email,phone,password,photoUrl}) {
    const old=session();
    const update={email:email.trim().toLowerCase(),data:{name:name.trim(),phone:phone.trim()},...(password?{password}: {})};
    const result=await request('/auth/v1/user',{method:'PUT',body:JSON.stringify(update)});
    const nextEmail=result.email || email.trim().toLowerCase();
    await request(`/rest/v1/profiles?id=eq.${encodeURIComponent(user.authUid)}`,{method:'PATCH',headers:{Prefer:'return=representation'},body:JSON.stringify({full_name:name.trim(),email:nextEmail,phone:phone.trim(),avatar_url:photoUrl || null})});
    if (old && result.access_token) save(result);
    return profileByUid(user.authUid);
  }
  async function listUsers() { const list = (await request('/rest/v1/profiles?select=*&order=public_id.asc')).map(profile); list.forEach(u => { if (u.phone && u.email) syncPhoneEntry(u.phone, u.email); }); return list; }
  async function adminAction(body) { return request('/functions/v1/admin-users',{method:'POST',body:JSON.stringify(body)}); }
  async function inviteUser(user,password) { const r=await adminAction({action:'invite',user,password}); return profile(r.profile); }
  async function updateUser(user,password) { const r=await adminAction({action:'update',user:{...user,pic:user.pic || user.photoUrl},password:password || null}); return profile(r.profile); }
  async function deleteUser(uid) { return adminAction({action:'delete',uid}); }
  async function grantPoints(uid,amount) { return adminAction({action:'award-points',recipientUid:uid,amount}); }
  async function notifyUser(recipientUid,type,title,body,icon='🔔') { return request('/functions/v1/send-notification',{method:'POST',body:JSON.stringify({recipientUid,type,title,body,icon})}); }
  async function listNotifications(uid) { const rows=await request(`/rest/v1/notifications?user_id=eq.${encodeURIComponent(uid)}&select=*&order=created_at.desc&limit=100`); return rows.map(n=>({id:n.id,docId:n.id,toId:0,type:n.type,title:n.title,msg:n.body,body:n.body,icon:n.icon,read:n.read,date:n.created_at,createdAt:n.created_at})); }
  async function markNotificationRead(uid,id) { return request(`/rest/v1/notifications?id=eq.${encodeURIComponent(id)}&user_id=eq.${encodeURIComponent(uid)}`,{method:'PATCH',headers:{Prefer:'return=minimal'},body:JSON.stringify({read:true})}); }
  async function fetchCollections() {
    if (!configured()) return [];
    return request('/rest/v1/app_collections?select=key,items,updated_at', {}, Boolean(session()?.access_token));
  }
  async function saveCollection(colKey, items) {
    if (!configured() || !session()?.access_token) return null;
    return request('/rest/v1/app_collections?on_conflict=key', {
      method: 'POST',
      headers: { Prefer: 'resolution=merge-duplicates,return=minimal' },
      body: JSON.stringify({ key: colKey, items: Array.isArray(items) ? items : [], updated_at: new Date().toISOString() }),
    });
  }
  let _ws = null, _wsTimer = null, _hbTimer = null, _pollTimer = null;
  function subscribeRealtime(onSync) {
    if (!configured()) return () => {};
    function connectWs() {
      try {
        if (_ws && (_ws.readyState === WebSocket.OPEN || _ws.readyState === WebSocket.CONNECTING)) return;
        const wsUrl = base().replace(/^http/, 'ws') + `/realtime/v1/websocket?apikey=${encodeURIComponent(key())}&vsn=1.0.0`;
        _ws = new WebSocket(wsUrl);
        _ws.onopen = () => {
          const token = session()?.access_token || key();
          _ws.send(JSON.stringify({
            topic: 'realtime:public:labaflow_sync',
            event: 'phx_join',
            payload: {
              config: {
                broadcast: { self: false },
                presence: { key: '' },
                postgres_changes: [
                  { event: '*', schema: 'public', table: 'app_collections' },
                  { event: '*', schema: 'public', table: 'notifications' },
                  { event: '*', schema: 'public', table: 'profiles' }
                ]
              },
              access_token: token
            },
            ref: '1'
          }));
          clearInterval(_hbTimer);
          _hbTimer = setInterval(() => {
            if (_ws && _ws.readyState === WebSocket.OPEN) {
              _ws.send(JSON.stringify({ topic: 'phoenix', event: 'heartbeat', payload: {}, ref: String(Date.now()) }));
            }
          }, 25000);
        };
        _ws.onmessage = (evt) => {
          try {
            const msg = JSON.parse(evt.data);
            if (msg.event === 'postgres_changes' && typeof onSync === 'function') {
              onSync(msg.payload?.data || {});
            }
          } catch (_) {}
        };
        _ws.onclose = () => {
          clearInterval(_hbTimer);
          clearTimeout(_wsTimer);
          _wsTimer = setTimeout(connectWs, 5000);
        };
      } catch (_) {}
    }
    connectWs();
    clearInterval(_pollTimer);
    _pollTimer = setInterval(() => {
      if (document.visibilityState !== 'hidden' && typeof onSync === 'function') {
        onSync({ table: 'poll' });
      }
    }, 5000);
    return () => {
      clearInterval(_hbTimer);
      clearInterval(_pollTimer);
      clearTimeout(_wsTimer);
      if (_ws) { try { _ws.close(); } catch (_) {} _ws = null; }
    };
  }
  global.LabaFlowSupabase={configured,signIn,register,phoneRegistered,signInWithGoogle,completeGoogleRedirect,restore,updateProfile,listUsers,inviteUser,updateUser,deleteUser,grantPoints,notifyUser,listNotifications,markNotificationRead,fetchCollections,saveCollection,subscribeRealtime,signOut};
})(window);
