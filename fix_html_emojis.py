path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

fixes = [
    # ── App shell / sidebar ──────────────────────────────────────────────
    # Brand icon in sidebar
    ('<div class="sb-icon">??</div>',              '<div class="sb-icon">🫧</div>'),
    # Placeholder text in sidebar user info
    ('<div class="sb-uname" id="sbName">—</div>',  '<div class="sb-uname" id="sbName">—</div>'),
    ('<div class="sb-urole" id="sbRole">—</div>',  '<div class="sb-urole" id="sbRole">—</div>'),

    # ── Topbar buttons ───────────────────────────────────────────────────
    # Admin/seller topbar theme + bell
    ('>??</button>\n\n        <button class="notif-bell" id="sellerBell"',
     '>🌙</button>\n\n        <button class="notif-bell" id="sellerBell"'),
    # Seller bell icon
    ('>?₱<span id="sellerBellCount"',              '>🔔<span id="sellerBellCount"'),
    # Customer portal topbar
    ('>??<span class="notif-bubble" id="custBellBubble"', '>🔔<span class="notif-bubble" id="custBellBubble"'),
    ('>??</button>\n\n      </div>\n\n    </div>',  '>🌙</button>\n\n      </div>\n\n    </div>'),

    # ── Notification panels ──────────────────────────────────────────────
    # Seller notification panel title (two instances)
    ('<span class="notif-head-title">?₱Notifications</span>',
     '<span class="notif-head-title">🔔 Notifications</span>'),
    # Notification close buttons
    ('<span class="notif-close" onclick="toggleNotifPanel()">?</span>',
     '<span class="notif-close" onclick="toggleNotifPanel()">✕</span>'),
    ('<span class="notif-close" onclick="toggleCustNotifPanel()">?</span>',
     '<span class="notif-close" onclick="toggleCustNotifPanel()">✕</span>'),

    # ── Auth buttons (sign in / register) ───────────────────────────────
    # Sign In button arrow
    ('onclick="doLogin()">Sign In ?</button>',      'onclick="doLogin()">Sign In →</button>'),
    # Register button arrow
    ('onclick="doRegister()">Create Account ?</button>',
     'onclick="doRegister()">Create Account →</button>'),

    # ── Payment modal ────────────────────────────────────────────────────
    ('<label>Amount (?)</label>',                   '<label>Amount (₱)</label>'),
    ('<option value="CASH">?₱Cash</option>',        '<option value="CASH">💵 Cash</option>'),
    ('<option value="GCASH">?₱GCash</option>',      '<option value="GCASH">💙 GCash</option>'),
    ('>?₱Scan the QR or send to the number above',  '>📱 Scan the QR or send to the number above'),

    # ── Restock modal ────────────────────────────────────────────────────
    ('<label>Cost per Unit (?) — for purchase log</label>',
     '<label>Cost per Unit (₱) — for purchase log</label>'),

    # ── Call overlay ─────────────────────────────────────────────────────
    ('<div class="call-avatar" id="callAvatar">?</div>',
     '<div class="call-avatar" id="callAvatar">👤</div>'),
    ('<div class="call-name" id="callName">Connecting—</div>',
     '<div class="call-name" id="callName">Connecting...</div>'),
    ('<div class="call-status call-pulse" id="callStatus">Calling—</div>',
     '<div class="call-status call-pulse" id="callStatus">Calling...</div>'),
    # Call action buttons
    ('<button class="call-action-btn mute" id="callMuteBtn" onclick="toggleCallMute()" title="Mute">??</button>',
     '<button class="call-action-btn mute" id="callMuteBtn" onclick="toggleCallMute()" title="Mute">🎤</button>'),
    ('<button class="call-action-btn end" onclick="endCall()" title="End Call">??</button>',
     '<button class="call-action-btn end" onclick="endCall()" title="End Call">📵</button>'),
    ('<button class="call-action-btn video-toggle" id="callVidBtn" style="display:none;" onclick="toggleCallVideo()" title="To',
     '<button class="call-action-btn video-toggle" id="callVidBtn" style="display:none;" onclick="toggleCallVideo()" title="To'),

    # ── Loader / misc ────────────────────────────────────────────────────
    ('Connecting—',    'Connecting...'),
    ('Calling—',       'Calling...'),
    ('Loading—',       'Loading...'),
]

count = 0
for old, new in fixes:
    if old != new and old in content:
        content = content.replace(old, new)
        count += 1
        print(f"  ✓ {repr(old[:70])}")

# Fix call video toggle button (the remaining part)
import re
content = re.sub(
    r'<button class="call-action-btn video-toggle"[^>]+>.*?</button>',
    '<button class="call-action-btn video-toggle" id="callVidBtn" style="display:none;" onclick="toggleCallVideo()" title="Toggle Video">📹</button>',
    content
)

# Fix theme buttons — they should show current mode text dynamically
# The static HTML just needs an initial emoji
content = content.replace(
    '>🌙</button>\n\n        <button class="notif-bell" id="sellerBell"',
    '>🌙</button>\n\n        <button class="notif-bell" id="sellerBell"'
)

print(f"\nTotal: {count} HTML emoji fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
