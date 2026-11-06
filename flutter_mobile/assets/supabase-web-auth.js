/* Public-key Supabase bridge for the standalone LabaFlow web client. */
(function (global) {
  'use strict';
  const config = global.LABAFLOW_SUPABASE_CONFIG || {};
  const sessionKey = 'labaflow.supabase.session.v1';
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
  async function signIn(email, password) {
    const result = await request('/auth/v1/token?grant_type=password', {method:'POST', body:JSON.stringify({email:email.trim().toLowerCase(), password})}, false);
    save(result); return profileByUid(result.user.id);
  }
  async function register({name,email,phone,password}) {
    const result = await request('/auth/v1/signup', {method:'POST', body:JSON.stringify({email:email.trim().toLowerCase(),password,data:{name:name.trim(),phone:phone.trim()}})}, false);
    if (!result.access_token || !result.user) throw new Error('Account created. Confirm your email, then sign in.');
    save(result); return profileByUid(result.user.id);
  }
  function signInWithGoogle() {
    requireConfig();
    const redirectTo=`${location.origin}/labaflow.html`;
    const authorize=new URL(`${base()}/auth/v1/authorize`);
    authorize.searchParams.set('provider','google');
    authorize.searchParams.set('redirect_to',redirectTo);
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
    if (!location.hash.includes('access_token=')) return;
    const params=new URLSearchParams(location.hash.slice(1));
    const accessToken=params.get('access_token'), refreshToken=params.get('refresh_token');
    if (!accessToken || !refreshToken) return;
    save({access_token:accessToken,refresh_token:refreshToken,token_type:params.get('token_type')||'bearer',expires_in:Number(params.get('expires_in')||3600),expires_at:Math.floor(Date.now()/1000)+Number(params.get('expires_in')||3600)});
    history.replaceState(null,'',`${location.pathname}${location.search}`);
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
  async function listUsers() { return (await request('/rest/v1/profiles?select=*&order=public_id.asc')).map(profile); }
  async function adminAction(body) { return request('/functions/v1/admin-users',{method:'POST',body:JSON.stringify(body)}); }
  async function inviteUser(user,password) { const r=await adminAction({action:'invite',user,password}); return profile(r.profile); }
  async function updateUser(user,password) { const r=await adminAction({action:'update',user:{...user,pic:user.pic || user.photoUrl},password:password || null}); return profile(r.profile); }
  async function deleteUser(uid) { return adminAction({action:'delete',uid}); }
  async function grantPoints(uid,amount) { return adminAction({action:'award-points',recipientUid:uid,amount}); }
  async function notifyUser(recipientUid,type,title,body,icon='🔔') { return request('/functions/v1/send-notification',{method:'POST',body:JSON.stringify({recipientUid,type,title,body,icon})}); }
  async function listNotifications(uid) { const rows=await request(`/rest/v1/notifications?user_id=eq.${encodeURIComponent(uid)}&select=*&order=created_at.desc&limit=100`); return rows.map(n=>({id:n.id,docId:n.id,toId:0,type:n.type,title:n.title,msg:n.body,body:n.body,icon:n.icon,read:n.read,date:n.created_at,createdAt:n.created_at})); }
  async function markNotificationRead(uid,id) { return request(`/rest/v1/notifications?id=eq.${encodeURIComponent(id)}&user_id=eq.${encodeURIComponent(uid)}`,{method:'PATCH',headers:{Prefer:'return=minimal'},body:JSON.stringify({read:true})}); }
  global.LabaFlowSupabase={configured,signIn,register,signInWithGoogle,completeGoogleRedirect,restore,updateProfile,listUsers,inviteUser,updateUser,deleteUser,grantPoints,notifyUser,listNotifications,markNotificationRead,signOut};
})(window);
