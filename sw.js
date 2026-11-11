/* ══════════════════════════════════════════════════════════════════════════
   LabaFlow Service Worker (sw.js)
   Handles OS Push Notifications even when the web app / tab is closed,
   minimized, or backgrounded ("app naka-destroy then may push notif").
══════════════════════════════════════════════════════════════════════════ */

const CACHE_NAME = 'labaflow-sw-v1';
let _bgTimer = null;
let _authInfo = null;
let _seenNotifIds = new Set();

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

async function showOsPushNotification(payload) {
  const title = payload.title || 'LabaFlow Laundry Update';
  const body = payload.body || payload.msg || 'You have a new update from Lab-a-Day Laundry.';
  const tag = payload.tag || ('labaflow-push-' + Date.now());
  const url = payload.url || './';
  return self.registration.showNotification(title, {
    body,
    icon: 'favicon.png',
    badge: 'favicon.png',
    tag,
    renotify: true,
    requireInteraction: true,
    vibrate: [220, 100, 220],
    data: { url, timestamp: Date.now(), ...(payload.data || {}) }
  });
}

/* Native Web Push event (works when browser/PWA is completely closed) */
self.addEventListener('push', (event) => {
  let payload = {
    title: '🫧 LabaFlow Notification',
    body: 'New laundry status or shop audit update received.'
  };
  if (event.data) {
    try {
      payload = { ...payload, ...event.data.json() };
    } catch (_) {
      payload.body = event.data.text() || payload.body;
    }
  }
  event.waitUntil(showOsPushNotification(payload));
});

/* Message channel from page (immediate or delayed background push when tab closes) */
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'SHOW_NOTIFICATION') {
    event.waitUntil(showOsPushNotification(data.payload || {}));
  } else if (data.type === 'SCHEDULE_BACKGROUND_PUSH') {
    const delayMs = Math.max(500, Number(data.delayMs) || 5000);
    const payload = data.payload || {
      title: '📡 LabaFlow Background Push Alert',
      body: 'Order & RFID status notification delivered while app is closed/backgrounded!'
    };
    event.waitUntil(
      new Promise((resolve) => {
        setTimeout(() => {
          showOsPushNotification(payload).then(resolve).catch(resolve);
        }, delayMs);
      })
    );
  } else if (data.type === 'SYNC_AUTH') {
    _authInfo = data.auth || null;
    if (Array.isArray(data.seenIds)) {
      data.seenIds.forEach((id) => _seenNotifIds.add(String(id)));
    }
    startBackgroundCheck();
  } else if (data.type === 'CLEAR_AUTH') {
    _authInfo = null;
    if (_bgTimer) { clearInterval(_bgTimer); _bgTimer = null; }
    _seenNotifIds.clear();
  }
});

async function pollSupabaseNotifications() {
  if (!_authInfo || !_authInfo.url || !_authInfo.anonKey || !_authInfo.accessToken || !_authInfo.userId) return;
  try {
    const endpoint = `${_authInfo.url}/rest/v1/notifications?user_id=eq.${encodeURIComponent(_authInfo.userId)}&read=eq.false&order=created_at.desc&limit=5`;
    const res = await fetch(endpoint, {
      headers: {
        apikey: _authInfo.anonKey,
        Authorization: `Bearer ${_authInfo.accessToken}`,
        Accept: 'application/json'
      }
    });
    if (!res.ok) return;
    const rows = await res.json();
    if (!Array.isArray(rows)) return;
    for (const row of rows) {
      const id = String(row.id || '');
      if (id && !_seenNotifIds.has(id)) {
        _seenNotifIds.add(id);
        await showOsPushNotification({
          title: `${row.icon || '🔔'} ${row.title || 'LabaFlow Update'}`,
          body: row.body || 'New notification from Lab-a-Day Laundry.',
          tag: 'labaflow-notif-' + id
        });
      }
    }
  } catch (_) {}
}

function startBackgroundCheck() {
  if (_bgTimer) clearInterval(_bgTimer);
  _bgTimer = setInterval(pollSupabaseNotifications, 15000);
}

self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'labaflow-notif-sync') {
    event.waitUntil(pollSupabaseNotifications());
  }
});

self.addEventListener('sync', (event) => {
  if (event.tag === 'labaflow-notif-sync') {
    event.waitUntil(pollSupabaseNotifications());
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.url) || './';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow(targetUrl);
    })
  );
});
