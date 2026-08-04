#!/usr/bin/env bash
# Structural checks for the create-ixmap skill.
#
# Run against the working copy BEFORE promoting it to this repo, so a release
# is "checked" mechanically and not just by eyeballing a diff.
#
#   ./check-skill.sh                              # check this repo
#   ./check-skill.sh ~/.claude/skills/create-ixmap  # check the working copy
#
# ERRORS fail the run (exit 1). WARNINGS are reported but do not fail — they
# flag things worth a look that have legitimate exceptions. Keeping heuristics
# out of the failure path is deliberate: a checker that cries wolf gets ignored.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${1:-$SCRIPT_DIR}"
[ -d "$DIR" ] || { echo "not a directory: $DIR" >&2; exit 2; }
cd "$DIR" || exit 2

ERR=0
WARN=0
err()  { printf '  \033[31mERROR\033[0m   %s\n' "$1"; ERR=$((ERR+1)); }
warn() { printf '  \033[33mWARN\033[0m    %s\n' "$1"; WARN=$((WARN+1)); }
ok()   { printf '  \033[32mok\033[0m      %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

echo "Checking: $DIR"

# ---------------------------------------------------------------- 1. structure
head_ "Structure"
for f in SKILL.md README.md skill-ui.yaml; do
  [ -f "$f" ] && ok "$f present" || err "$f missing"
done
if head -1 SKILL.md 2>/dev/null | grep -q '^---$'; then
  for k in name description; do
    grep -q "^$k:" SKILL.md && ok "frontmatter has $k" || err "frontmatter missing $k"
  done
else
  err "SKILL.md has no YAML frontmatter"
fi

# ------------------------------------------------------------------- 2. yaml
head_ "skill-ui.yaml"
# js-yaml resolves relative to the *invoking* directory, so checking an
# arbitrary target dir would silently skip these checks and still print ok.
# Search a few known roots and pin NODE_PATH so the check always really runs.
for cand in "$SCRIPT_DIR" "$HOME" "$DIR"; do
  if [ -d "$cand/node_modules/js-yaml" ]; then
    export NODE_PATH="$cand/node_modules${NODE_PATH:+:$NODE_PATH}"
    break
  fi
done
if ! command -v node >/dev/null 2>&1; then
  err "node not found — cannot validate skill-ui.yaml (install node, or this release is unchecked)"
elif ! node -e "require('js-yaml')" 2>/dev/null; then
  err "js-yaml unresolvable (npm install js-yaml) — skill-ui.yaml NOT validated; do not treat this run as a pass"
else
  YAML_OUT=$(node -e '
    const y=require("js-yaml"), f=require("fs");
    let d;
    try { d = y.load(f.readFileSync("skill-ui.yaml","utf8")); }
    catch(e){ console.log("ERR|does not parse: "+e.message); process.exit(0); }
    const P=(d.parameters||[]).map(p=>p.name), S=new Set(P);
    console.log("OK|parses ("+P.length+" parameters)");
    if (typeof (d.skill||{}).version !== "string")
      console.log("ERR|skill.version must be a quoted string (got "+typeof (d.skill||{}).version+")");
    // dangling references
    (d.groups||[]).forEach(g=>(g.parameters||[]).forEach(p=>{
      if(!S.has(p)) console.log("ERR|group "+g.name+" references undefined parameter: "+p); }));
    (d.presets||[]).forEach(pr=>Object.keys(pr.parameters||{}).forEach(k=>{
      if(!S.has(k)) console.log("ERR|preset "+pr.name+" references undefined parameter: "+k); }));
    (((d.validation||{}).rules)||[]).forEach(r=>{
      (r.requires||[]).forEach(k=>{ if(!S.has(k)) console.log("ERR|rule "+r.name+" requires undefined parameter: "+k); });
      Object.keys(r.suggests||{}).forEach(k=>{ if(!S.has(k)) console.log("ERR|rule "+r.name+" suggests undefined parameter: "+k); });
    });
    // depends_on.viztype must resolve against the viztype enum
    const vt=(d.parameters||[]).find(p=>p.name==="viztype");
    if(vt && vt.options){
      const en=[].concat(...(Array.isArray(vt.options)?[vt.options]:Object.values(vt.options))).map(o=>o&&o.value).filter(Boolean);
      (d.parameters||[]).forEach(p=>{
        const dv=p.depends_on && p.depends_on.viztype;
        if(Array.isArray(dv)) dv.filter(v=>!en.includes(v)).forEach(v=>
          console.log("ERR|"+p.name+".depends_on.viztype lists a value absent from the viztype enum: "+v));
      });
      console.log("OK|viztype enum has "+en.length+" values");
    }
    // params defined but never grouped
    const G=new Set(); (d.groups||[]).forEach(g=>(g.parameters||[]).forEach(p=>G.add(p)));
    P.filter(p=>!G.has(p)).forEach(p=>console.log("WARN|parameter not in any group: "+p));
  ')
  while IFS='|' read -r lvl msg; do
    case "$lvl" in OK) ok "$msg";; ERR) err "$msg";; WARN) warn "$msg";; esac
  done <<< "$YAML_OUT"
fi

# ------------------------------------------------------- 3. markdown integrity
head_ "Markdown"
for f in *.md; do
  [ -e "$f" ] || continue
  n=$(grep -c '^```' "$f")
  [ $((n % 2)) -eq 0 ] || err "$f has an unclosed code fence ($n fences)"
done
[ "$ERR" -eq 0 ] && ok "all code fences balanced"

# referenced companion docs exist
missing=0
for f in *.md; do
  [ -e "$f" ] || continue
  grep -oE '\*\*[A-Za-z0-9_-]+\.md\b' "$f" | tr -d '*' | sort -u | while read -r ref; do
    [ -e "$ref" ] || { echo "$f -> $ref"; }
  done
done | sort -u | while read -r line; do
  [ -n "$line" ] && err "reference to a file that does not exist: $line"
done
ok "companion-doc references resolved"

# ------------------------------------------------ 4. nonexistent API surface
head_ "Nonexistent / wrong API identifiers"
# Executable artifacts (templates, yaml) must not contain these at all — an
# occurrence there ships broken code, so it is an ERROR.
#
# Documentation may legitimately quote a wrong form to teach against it
# ("// WRONG:", "❌ ...", "NEVER use x"). Flagging those is a false failure, so
# in .md a hit is only reported when it is NOT inside such a teaching block —
# and then only as a WARNING, since prose has more valid shapes than we can
# enumerate. Verify before acting on it.
TEACH_RE='WRONG|Wrong|❌|✗|NEVER|Never|never|not valid|NOT valid|does ?n.?t exist|do(es)? not exist|deprecated|instead of|accepted variant|not an alias|silently'

# $1 = extended-regex pattern (escape any parens yourself), $2 = description.
# Uses grep throughout — passing patterns into awk's regex engine broke on
# unescaped parens and made whole scans fail silently while still printing "ok".
check_absent() {
  local pat="$1" desc="$2" hard=0 soft=0 f n win

  # --- executable artifacts (.html/.yaml): any occurrence is a hard error
  for f in *.html *.yaml; do
    [ -e "$f" ] || continue
    while IFS=: read -r n _; do
      [ -n "$n" ] || continue
      err "$desc in an executable artifact → $f:$n"
      hard=$((hard+1))
    done < <(grep -nE -- "$pat" "$f" 2>/dev/null || true)
  done

  # --- docs (.md): warn only when the hit is NOT inside a teaching block,
  #     judged from a 3-line window ending at the hit.
  for f in *.md; do
    [ -e "$f" ] || continue
    while IFS=: read -r n _; do
      [ -n "$n" ] || continue
      win=$(sed -n "$(( n > 2 ? n-2 : 1 )),${n}p" "$f")
      if ! printf '%s' "$win" | grep -qE -- "$TEACH_RE"; then
        warn "$desc in prose (verify — may be a valid mention) → $f:$n"
        soft=$((soft+1))
      fi
    done < <(grep -nE -- "$pat" "$f" 2>/dev/null || true)
  done

  [ "$hard" -eq 0 ] && [ "$soft" -eq 0 ] && ok "no $desc"
}
check_absent 'ixmaps\.Layer\('            'ixmaps.Layer( (capital L; use ixmaps.layer)'
check_absent '(show|hide)Layer\b'         'showLayer/hideLayer (use showTheme/hideTheme)'
check_absent 'basemap_opacity'            'basemap_opacity (real key is basemapopacity)'
check_absent 'CHART\|GRID\|AGGREGATE'     'CHART|GRID|AGGREGATE (nonexistent type)'
check_absent '\.tooltip\('                '.tooltip() (use .meta({tooltip}))'
check_absent 'fillcolor:'                 'fillcolor (use colorscheme)'
check_absent '(strokecolor|strokewidth):' 'strokecolor/strokewidth (use linecolor/linewidth)'

# bare `opacity:` inside a style block is nearly always meant to be fillopacity
bare=$(grep -rn '^[[:space:]]*opacity:' *.md *.html 2>/dev/null || true)
if [ -n "$bare" ]; then
  while IFS= read -r h; do warn "bare 'opacity:' — did you mean fillopacity? ${h%%:*}:$(echo "$h" | cut -d: -f2)"; done <<< "$bare"
else
  ok "no bare 'opacity:' in style blocks"
fi

# table.select() with a range operator (>,<,>=,<=,BETWEEN) compared against a
# date-shaped literal ("YYYY-MM-DD") is ALWAYS this bug: both sides go through
# Number(), which is NaN for a date string, so the comparison is always false
# and select() silently returns zero rows. This pattern-match has no false
# positives — it's a hard error, not a style warning.
range_on_date=$(grep -rnE '\.select\([^)]*(>=|<=|>|<|BETWEEN)[^)]*[0-9]{4}-[0-9]{2}-[0-9]{2}' *.md *.html 2>/dev/null || true)
if [ -n "$range_on_date" ]; then
  while IFS= read -r h; do
    err "select() range operator vs a date literal — Number(date) is NaN, always returns 0 rows → $h"
  done <<< "$range_on_date"
else
  ok "no select() range comparison against a date-shaped literal"
fi

# ------------------------------------------------- 5. render-contract basics
head_ "Render contract (templates)"
for t in template*.html; do
  [ -e "$t" ] || continue
  grep -q 'ixmaps-flat@\|ixmaps\.js' "$t" || err "$t: no ixmaps CDN script tag"
  grep -q 'id="map"' "$t"                 || warn "$t: no #map div found"
  grep -qE 'height:[[:space:]]*(100vh|[0-9]+px|100%)' "$t" || warn "$t: #map may have no height"
  grep -q 'var map\b\|const map =\|let map =' "$t" && err "$t: uses reserved variable name 'map'"

  # Map call sequence: Map -> view -> options -> layer. Checked for EVERY template,
  # including placeholder-driven ones — the sequence is independent of where the
  # layers come from, so this must run before the {{LAYERS}} exemption below.
  # .view() must precede every .layer() (layer symbols size against the current
  # view) and, by convention, .options() too.
  seq=$(grep -o 'ixmaps\.Map(\|\.view(\|\.options(\|\.layer(' "$t" \
        | sed 's/ixmaps\.Map(/M/;s/\.view(/V/;s/\.options(/O/;s/\.layer(/L/' \
        | awk '!seen[$0]++' | tr -d '\n')
  # Evaluate in order of severity — the first matching condition wins.
  if [ -z "$seq" ]; then
    warn "$t: no ixmaps.Map/.view/.options/.layer calls found — cannot determine sequence"
  elif case "$seq" in *M*) false;; *) true;; esac; then
    warn "$t: no ixmaps.Map( call found (sequence '$seq')"
  elif case "$seq" in *V*) false;; *) true;; esac; then
    err "$t: no .view() at all (sequence '$seq') — the map never gets a defined view"
  elif case "$seq" in *L*V*) true;; *) false;; esac; then
    err "$t: sequence $seq — .layer() precedes .view(); layer symbols would size against an unset view"
  elif case "$seq" in *O*V*) true;; *) false;; esac; then
    warn "$t: sequence $seq — .options() precedes .view(); canonical is M>V>O>L (§ Map call sequence)"
  else
    ok "$t: map call sequence $seq (view before options and layers)"
  fi

  # A template whose layers arrive via a placeholder ({{LAYERS}}) legitimately
  # contains no .define() / showdata of its own — the filler supplies them.
  # Requiring them here would be a false failure.
  if grep -qE '\{\{ *LAYERS *\}\}' "$t"; then
    ok "$t: layers injected via {{LAYERS}} — .define()/showdata are the filler's job"
    continue
  fi

  grep -q '\.define()' "$t" || err "$t: no .define() and no {{LAYERS}} placeholder — no layer would register"

  # showdata gates the draw phase. Exempt when the whole style object is a
  # placeholder (.style({{STYLE}})) — the filler supplies it — but require the
  # template to *say so*, or the filler can silently omit it and ship a blank map.
  if grep -qE '\.style\(\{\{ *[A-Z_]+ *\}\}\)' "$t"; then
    grep -qi 'showdata' "$t" \
      && ok "$t: style is a placeholder, and showdata is called out for the filler" \
      || warn "$t: .style() is an opaque {{placeholder}} with no showdata reminder — filler may omit it and render blank"
  elif grep -q '\.style({' "$t" && ! grep -q 'showdata' "$t"; then
    grep -q 'SILENT' "$t" || warn "$t: has .style() but no showdata:\"true\" (invisible unless every layer is SILENT)"
  fi
done
ok "templates checked"

# ------------------------------------------------------ 6. self-consistency
head_ "Self-consistency"
if [ -f EXAMPLES.md ] && [ -f README.md ]; then
  actual=$(grep -c '^### Example' EXAMPLES.md || echo 0)
  claimed=$(grep -oE '\(([0-9]+) examples\)' README.md | grep -oE '[0-9]+' | head -1)
  if [ -n "${claimed:-}" ] && [ "$claimed" != "$actual" ]; then
    err "README claims $claimed examples; EXAMPLES.md has $actual '### Example' headings"
  else
    ok "README example count matches EXAMPLES.md ($actual)"
  fi
fi
if [ -f SKILL.md ] && [ -f README.md ]; then
  lines=$(wc -l < SKILL.md | tr -d ' ')
  claimed=$(grep -oE 'SKILL\.md[^)]*\(~?([0-9,]+) lines\)' README.md | grep -oE '[0-9,]+ lines' | grep -oE '[0-9,]+' | tr -d ',' | head -1)
  if [ -n "${claimed:-}" ]; then
    diffpct=$(( (claimed > lines ? claimed - lines : lines - claimed) * 100 / (lines > 0 ? lines : 1) ))
    [ "$diffpct" -gt 15 ] \
      && warn "README says SKILL.md is ~$claimed lines; actual $lines (${diffpct}% off)" \
      || ok "README SKILL.md line count within tolerance ($lines)"
  fi
fi

# ------------------------------------------------------------------ summary
printf '\n\033[1mSummary\033[0m  errors: %d   warnings: %d\n' "$ERR" "$WARN"
if [ "$ERR" -gt 0 ]; then
  echo "NOT release-ready — fix the errors above."
  exit 1
fi
[ "$WARN" -gt 0 ] && echo "Release-ready (review the warnings)." || echo "Release-ready."
exit 0
