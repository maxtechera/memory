#!/usr/bin/env bash
set -euo pipefail
FONT=$(fc-match -f '%{file}\n' 'DejaVu Sans' | head -1)
ROOT=/data/workspace/repos/memory/content/reels/MAX-547
OUT="$ROOT/videos"
TXT="$ROOT/render-text"
mkdir -p "$OUT" "$TXT"

render() {
  local slug="$1"
  local headline="$2"
  local body="$3"
  local cta="$4"
  printf '%s\n' "$headline" > "$TXT/$slug-headline.txt"
  printf '%s\n' "$body" > "$TXT/$slug-body.txt"
  printf '%s\n' "$cta" > "$TXT/$slug-cta.txt"
  ffmpeg -y -f lavfi -i color=c=0x0b1020:s=1080x1920:d=12 \
    -vf "drawtext=fontfile=$FONT:textfile=$TXT/$slug-headline.txt:fontcolor=white:fontsize=72:x=80:y=220:line_spacing=12,\
         drawtext=fontfile=$FONT:textfile=$TXT/$slug-body.txt:fontcolor=0xcbd5e1:fontsize=42:x=80:y=640:line_spacing=18,\
         drawtext=fontfile=$FONT:textfile=$TXT/$slug-cta.txt:fontcolor=0x7dd3fc:fontsize=40:x=80:y=1560:line_spacing=16,\
         drawtext=fontfile=$FONT:text='MAX-547 /memory':fontcolor=0x7dd3fc:fontsize=30:x=80:y=100,\
         drawtext=fontfile=$FONT:text='github.com/maxtechera/memory':fontcolor=white:fontsize=32:x=80:y=1760" \
    -c:v libx264 -pix_fmt yuv420p -threads 2 "$OUT/$slug.mp4"
}

render "01-problem-agitate-solve" "Your AI agent forgot everything again." $'Same project. Same goals. Zero memory.\nRe-explain the project. Re-explain the last decision. Re-explain the current focus.\nInstall /memory once and let hooks persist context across compactions.' "DM MEMORY for the free install guide"
render "02-contrarian" "The problem is not your prompt." $'Better prompting does not fix stateless sessions.\nYou need continuity: HOT in context, WARM by topic, COLD by search.\nThat is what /memory changes.' "Comment install for the repo link"
render "03-specific-number" "Three memory tiers beat one giant context dump." $'HOT stays loaded. WARM loads on demand. COLD stays searchable.\nSmaller active context, better continuity, less token waste.\nOne setup step, three tiers, zero re-explaining.' "Link in bio or DM MEMORY"
render "04-insider-reveal" "The real trick is write-ahead memory." $'The WAL-style flow writes session state before the reply.\nThen the pre-compact hook flushes it before context disappears.\nThat is why /memory survives compaction.' "DM MEMORY for the install guide"
render "05-testimonial" "The moment my agent stopped forgetting, everything sped up." $'New sessions already knew the repo, the last decision, and the current focus.\nThe work felt continuous instead of disposable.\nThat is what /memory changed in practice.' "Comment install or grab the repo"
