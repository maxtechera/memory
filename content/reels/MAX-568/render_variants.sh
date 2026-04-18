#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/videos"
THUMBS="$ROOT/thumbnails"
TXT="$ROOT/render-text"
FONT=$(fc-match -f '%{file}\n' 'DejaVu Sans' | head -1)
mkdir -p "$OUT" "$THUMBS" "$TXT"

render_variant() {
  local slug="$1"
  local kicker="$2"
  local headline="$3"
  local scene1="$4"
  local scene2="$5"
  local scene3="$6"
  local cta="$7"

  printf '%s\n' "$headline" > "$TXT/$slug-headline.txt"
  printf '%s\n' "$scene1" > "$TXT/$slug-scene1.txt"
  printf '%s\n' "$scene2" > "$TXT/$slug-scene2.txt"
  printf '%s\n' "$scene3" > "$TXT/$slug-scene3.txt"
  printf '%s\n' "$cta" > "$TXT/$slug-cta.txt"

  ffmpeg -y -f lavfi -i color=c=0x08111f:s=1080x1920:d=12 -vf "
    drawbox=x=60:y=60:w=960:h=180:color=0x10233f:t=fill,
    drawbox=x=60:y=300:w=960:h=1220:color=0x0d1b31:t=fill,
    drawbox=x=60:y=1580:w=960:h=210:color=0x10233f:t=fill,
    drawtext=fontfile=$FONT:text='${kicker}':fontcolor=0x7dd3fc:fontsize=34:x=90:y=110,
    drawtext=fontfile=$FONT:textfile=$TXT/$slug-headline.txt:fontcolor=white:fontsize=68:x=90:y=180:line_spacing=12,
    drawtext=fontfile=$FONT:text='01':enable='lt(t,4)':fontcolor=0x7dd3fc:fontsize=40:x=90:y=380,
    drawtext=fontfile=$FONT:textfile=$TXT/$slug-scene1.txt:enable='lt(t,4)':fontcolor=0xe2e8f0:fontsize=44:x=160:y=382:line_spacing=16,
    drawtext=fontfile=$FONT:text='02':enable='between(t,4,8)':fontcolor=0x7dd3fc:fontsize=40:x=90:y=380,
    drawtext=fontfile=$FONT:textfile=$TXT/$slug-scene2.txt:enable='between(t,4,8)':fontcolor=0xe2e8f0:fontsize=44:x=160:y=382:line_spacing=16,
    drawtext=fontfile=$FONT:text='03':enable='gte(t,8)':fontcolor=0x7dd3fc:fontsize=40:x=90:y=380,
    drawtext=fontfile=$FONT:textfile=$TXT/$slug-scene3.txt:enable='gte(t,8)':fontcolor=0xe2e8f0:fontsize=44:x=160:y=382:line_spacing=16,
    drawtext=fontfile=$FONT:textfile=$TXT/$slug-cta.txt:fontcolor=0x7dd3fc:fontsize=40:x=90:y=1650:line_spacing=14,
    drawtext=fontfile=$FONT:text='github.com/maxtechera/memory':fontcolor=white:fontsize=30:x=90:y=1765,
    drawtext=fontfile=$FONT:text='OSS demo-first reel pack':fontcolor=0x94a3b8:fontsize=28:x=90:y=1820
  " -c:v libx264 -pix_fmt yuv420p -r 30 "$OUT/$slug.mp4"

  ffmpeg -y -i "$OUT/$slug.mp4" -vf "select=eq(n\,0)" -vframes 1 -update 1 "$THUMBS/$slug.png"
}

render_variant \
  "01-problem-agitate-solve" \
  "MAX-568 /memory" \
  "Your AI forgets everything." \
  $'Open a fresh session.\nThe repo is gone.\nThe last decision is gone.' \
  $'So you re-explain the brief,\nrestate the task,\nand burn tokens catching up.' \
  $'Install /memory once.\nNext session resumes with repo,\nlast decision, and current focus.' \
  "DM MEMORY for the free install guide"

render_variant \
  "02-contrarian" \
  "MAX-568 /memory" \
  "The problem is not your prompt." \
  $'Longer prompts do not fix\na stateless agent.\nThey just make the reset slower.' \
  $'The real gap is continuity.\nYour agent needs memory,\nnot a bigger context dump.' \
  $'HOT stays loaded.\nWARM loads by topic.\nCOLD stays searchable.' \
  "Comment install for the repo link"

render_variant \
  "03-specific-number" \
  "MAX-568 /memory" \
  "Three tiers beat one giant prompt." \
  $'HOT stores the active state\nyou need every session.' \
  $'WARM keeps reusable context\nready by topic or project.' \
  $'COLD keeps deep history searchable,\nso continuity survives compaction.' \
  "Link in bio or DM MEMORY"

render_variant \
  "04-insider-reveal" \
  "MAX-568 /memory" \
  "The pre-compact flush is the secret." \
  $'Most memory setups fail\nright before the context resets.' \
  $'/memory writes session state\nbefore the reply, then flushes again\nbefore compaction lands.' \
  $'That is why the next session\ncan actually pick up where\nthe last one stopped.' \
  "DM MEMORY for the install guide"

render_variant \
  "05-testimonial" \
  "MAX-568 /memory" \
  "The moment my agent stopped forgetting, work sped up." \
  $'Every morning used to start\nwith the same long re-brief.' \
  $'After /memory, new sessions\nalready knew the repo,\nlast decision, and next step.' \
  $'The work felt continuous,\nnot disposable.\nThat changed everything.' \
  "Comment install or grab the repo"

ffmpeg -y \
  -i "$THUMBS/01-problem-agitate-solve.png" \
  -i "$THUMBS/02-contrarian.png" \
  -i "$THUMBS/03-specific-number.png" \
  -i "$THUMBS/04-insider-reveal.png" \
  -i "$THUMBS/05-testimonial.png" \
  -filter_complex "[0:v][1:v][2:v][3:v][4:v]hstack=inputs=5,scale=1620:576" \
  -frames:v 1 -update 1 "$ROOT/proof-board.png"

echo "Rendered videos to $OUT"
echo "Rendered thumbnails to $THUMBS"
