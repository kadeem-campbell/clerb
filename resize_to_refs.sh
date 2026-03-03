#!/usr/bin/env bash
set -euo pipefail

mkdir -p refs

curl -fsSL "https://rvs-social-event.vercel.app/Assets/User-Avatar-1.svg" -o refs/User-Avatar-1.svg
curl -fsSL "https://rvs-social-event.vercel.app/Assets/User-Avatar-2.svg" -o refs/User-Avatar-2.svg
curl -fsSL "https://rvs-social-event.vercel.app/Assets/User-Avatar-3.svg" -o refs/User-Avatar-3.svg
curl -fsSL "https://rvs-social-event.vercel.app/Assets/User-Avatar-4.svg" -o refs/User-Avatar-4.svg
curl -fsSL "https://rvs-social-event.vercel.app/Assets/User-Avatar-5.svg" -o refs/User-Avatar-5.svg

python3 - <<'PY' > refs/target_dims.txt
import re, pathlib
def dims(svg_text):
    w = re.search(r'\bwidth="([^"]+)"', svg_text)
    h = re.search(r'\bheight="([^"]+)"', svg_text)
    vb = re.search(r'\bviewBox="([^"]+)"', svg_text)
    def parse(v):
        v=v.strip()
        v=re.sub(r'px$', '', v)
        try: return float(v)
        except: return None
    if w and h:
        W=parse(w.group(1)); H=parse(h.group(1))
        if W and H: return int(round(W)), int(round(H))
    if vb:
        parts=[p for p in vb.group(1).replace(',', ' ').split() if p]
        if len(parts)==4:
            return int(round(float(parts[2]))), int(round(float(parts[3])))
    return None

rows=[]
for i in range(1,6):
    p=pathlib.Path("refs")/f"User-Avatar-{i}.svg"
    txt=p.read_text(encoding="utf-8", errors="ignore")
    d=dims(txt)
    if not d:
        raise SystemExit(f"Could not parse dims for {p}")
    rows.append((i, d[0], d[1]))

print("\n".join([f"{i} {w} {h}" for i,w,h in rows]))
PY

echo "Target dims:"
cat refs/target_dims.txt

command -v magick >/dev/null 2>&1 || { echo "Install ImageMagick: brew install imagemagick"; exit 1; }

mkdir -p backups_png
cp -f User-Avatar-*.png backups_png/ 2>/dev/null || true

while read -r i w h; do
  in="User-Avatar-$i.png"
  if [ ! -f "$in" ]; then
    echo "Missing $in"
    continue
  fi
  magick "$in" -resize "${w}x${h}!" "$in"
  echo "✅ Resized $in to ${w}x${h}"
done < refs/target_dims.txt

echo ""
echo "Final pixel sizes:"
magick identify -format "%f %wx%h\n" User-Avatar-*.png
