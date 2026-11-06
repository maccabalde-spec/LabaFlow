path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix 1: Star display in review cards (₱ used instead of ★/☆) ──────────
old1 = "${'₱'.repeat(r.rating)}${'₱'.repeat(5-r.rating)}"
new1 = "${'★'.repeat(r.rating)}${'☆'.repeat(5-r.rating)}"
if old1 in content:
    content = content.replace(old1, new1)
    count += 1
    print("✓ Fixed: review stars using ★/☆")

# ── Fix 2: Success message broken emoji ──────────────────────────────────
old2 = "msg.textContent='₱Thank you for your review!'"
new2 = "msg.textContent='✅ Thank you for your review!'"
if old2 in content:
    content = content.replace(old2, new2)
    count += 1
    print("✓ Fixed: review success message")

# ── Fix 3: Empty rating display (broken char) ────────────────────────────
import re
# ratingBig shows — when no reviews
content = re.sub(
    r"ratingBig\.textContent='[^']{1,5}';",
    "ratingBig.textContent='—';",
    content
)
count += 1
print("✓ Fixed: empty rating display")

# ── Fix 4: Make submitLandingReview save to Firestore properly ────────────
# Currently uses DB.set (bulk rewrite) — change to DB.upsert for single item
old4 = """  reviews.push({id:C.nextId('reviews'),name,service:service||'Laundry Service',text,rating:rvRating,date:new Date().toISOString()});

  DB.set('reviews',reviews);"""

new4 = """  const newReview={id:C.nextId('reviews'),name,service:service||'Laundry Service',text,rating:rvRating,date:new Date().toISOString()};

  reviews.push(newReview);C.set('reviews',reviews);

  DB.upsert('reviews',newReview);"""

if old4 in content:
    content = content.replace(old4, new4)
    count += 1
    print("✓ Fixed: submitLandingReview saves to Firestore via upsert")

# ── Fix 5: renderLandingReviews — load from Firestore then render ─────────
# Currently uses C.get('reviews') which may be empty on first load
# Change to also listen to Firestore reviews in real-time
old5 = """function renderLandingReviews(){

  const reviews=C.get('reviews');

  const grid=g('lpReviewsGrid');"""

new5 = """function renderLandingReviews(reviewsData){

  /* Accept optional data param (from real-time listener) or use cache */
  const reviews = reviewsData || C.get('reviews');

  const grid=g('lpReviewsGrid');"""

if old5 in content:
    content = content.replace(old5, new5)
    count += 1
    print("✓ Fixed: renderLandingReviews accepts live data param")

# ── Fix 6: Add Firestore listener for reviews in startRealtimeListeners ───
old6 = """  _unsubListeners.push(DB.listen('transactions', data=>{
    _cache['transactions']=data;
  }));"""

new6 = """  _unsubListeners.push(DB.listen('transactions', data=>{
    _cache['transactions']=data;
  }));

  /* Reviews — real-time for landing page */
  _unsubListeners.push(DB.listen('reviews', data=>{
    _cache['reviews']=data;
    if(typeof renderLandingReviews==='function') try{renderLandingReviews(data);}catch(e){}
  }));"""

if old6 in content:
    content = content.replace(old6, new6)
    count += 1
    print("✓ Fixed: real-time Firestore listener for reviews")

# ── Fix 7: Price row sub — em dash showing as ? ──────────────────────────
# The — character in HTML should render fine but let's normalize
content = content.replace(
    'Base 5 kg \ufffd +\u20b138/kg extra',
    'Base 5 kg — +₱38/kg extra'
)
content = content.replace(
    'Base 7 kg \ufffd +\u20b125/kg extra',
    'Base 7 kg — +₱25/kg extra'
)
# Also fix the encoded versions
content = content.replace(
    'Base 5 kg &mdash; +',
    'Base 5 kg — +'
)
content = content.replace(
    'Base 7 kg &mdash; +',
    'Base 7 kg — +'
)
print("✓ Checked price row dashes")

# ── Fix 8: lp-hero-note — fix any remaining broken chars ─────────────────
old8 = '<div class="lp-hero-note">✅ Walk-in welcome'
if old8 in content:
    print("✓ Hero note already fixed")

# Fix middot separators in hero note
content = content.replace(
    '✅ Walk-in welcome &nbsp;\ufffd&nbsp; 💳 GCash & Cash accepted &nbsp;\ufffd&nbsp; 📡 RFID-tracked',
    '✅ Walk-in welcome &nbsp;·&nbsp; 💳 GCash & Cash accepted &nbsp;·&nbsp; 📡 RFID-tracked'
)
content = content.replace(
    'Walk-in welcome &nbsp;?&nbsp;',
    'Walk-in welcome &nbsp;·&nbsp;'
)
content = content.replace(
    'Cash accepted &nbsp;?&nbsp;',
    'Cash accepted &nbsp;·&nbsp;'
)
count += 1
print("✓ Fixed hero note separators")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
