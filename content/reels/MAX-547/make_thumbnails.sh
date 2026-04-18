#!/usr/bin/env bash
set -euo pipefail
ROOT=/data/workspace/repos/memory/content/reels/MAX-547
OUT="$ROOT/thumbnails"
mkdir -p "$OUT"
make_html() {
  local slug="$1"
  local headline="$2"
  local body="$3"
  cat > "$OUT/$slug.html" <<HTML
<!doctype html><html><head><meta charset='utf-8'><style>
body{margin:0;width:1080px;height:1920px;background:linear-gradient(160deg,#0b1020,#1d4ed8 60%,#10b981);color:#fff;font-family:Arial,sans-serif;overflow:hidden}
.wrap{padding:88px 84px;position:relative;height:100%;box-sizing:border-box}.k{font-size:30px;letter-spacing:.2em;color:#7dd3fc;text-transform:uppercase;font-weight:700}
.h{font-size:86px;line-height:.98;margin-top:36px;font-weight:700}.b{font-size:46px;line-height:1.25;margin-top:34px;color:#cbd5e1;max-width:860px}.f{position:absolute;left:84px;bottom:120px;font-size:30px}
</style></head><body><div class='wrap'><div class='k'>MAX-547 /memory</div><div class='h'>$headline</div><div class='b'>$body</div><div class='f'>github.com/maxtechera/memory</div></div></body></html>
HTML
  chromium --headless --no-sandbox --disable-gpu --hide-scrollbars --screenshot="$OUT/$slug.png" --window-size=1080,1920 "file://$OUT/$slug.html"
}
make_html "01-problem-agitate-solve" "Your AI agent forgot everything again." "HOT, WARM, COLD memory that survives session compactions."
make_html "02-contrarian" "The problem is not your prompt." "Better prompting will not fix stateless sessions."
make_html "03-specific-number" "Three memory tiers beat one giant context dump." "One setup step, three tiers, zero re-explaining."
make_html "04-insider-reveal" "The real trick is write-ahead memory." "The pre-compact flush is why /memory survives context loss."
make_html "05-testimonial" "The moment my agent stopped forgetting, everything sped up." "New sessions already knew the repo, the last decision, and the focus."
cat > "$ROOT/proof/proof-board.html" <<HTML
<!doctype html><html><head><meta charset='utf-8'><style>body{margin:0;background:#020617;color:#fff;font-family:Arial,sans-serif}.wrap{padding:48px}h1{font-size:52px;margin:0 0 12px}p{font-size:24px;color:#cbd5e1}.grid{display:grid;grid-template-columns:1fr 1fr;gap:28px;margin-top:28px}.card{background:#0f172a;border:1px solid rgba(255,255,255,.12);border-radius:24px;padding:18px}.card img{width:100%;border-radius:16px;display:block}.meta{font-size:24px;margin-top:10px;color:#e2e8f0}</style></head><body><div class='wrap'><h1>MAX-547 /memory reel proof board</h1><p>Five rendered MP4 variants plus thumbnail covers stored in maxtechera/memory.</p><div class='grid'><div class='card'><img src='../thumbnails/01-problem-agitate-solve.png'><div class='meta'>Problem agitate solve</div></div><div class='card'><img src='../thumbnails/02-contrarian.png'><div class='meta'>Contrarian</div></div><div class='card'><img src='../thumbnails/03-specific-number.png'><div class='meta'>Specific number</div></div><div class='card'><img src='../thumbnails/04-insider-reveal.png'><div class='meta'>Insider reveal</div></div><div class='card'><img src='../thumbnails/05-testimonial.png'><div class='meta'>Testimonial</div></div></div></div></body></html>
HTML
chromium --headless --no-sandbox --disable-gpu --hide-scrollbars --screenshot="$ROOT/proof/proof-board.png" --window-size=1600,3200 "file://$ROOT/proof/proof-board.html"
