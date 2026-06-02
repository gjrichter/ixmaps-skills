# CSS Conflicts with External Frameworks (Bootstrap etc.)

> Reference detail for **SKILL.md § CSS Conflicts with External Frameworks**.

**Never load Bootstrap 3 (or similar CSS frameworks) alongside ixmaps.** Bootstrap 3's `.hidden { display:none !important }` rule silently breaks ixmaps UI elements — toolbar buttons, tooltip, and context menu all become invisible because:
- ixmaps creates elements with `class="hidden"` and controls visibility via `element.style.display = "flex/block/inline"`
- Bootstrap's `!important` on `.hidden` beats inline styles — ixmaps can never win
- The failure is **silent**: no JS errors, elements just stay invisible

## Root fix: standalone facet CSS

Instead of Bootstrap, include ~35 lines of standalone CSS that covers only what `show_facets.js` generates:

```css
/* ── Standalone facet CSS (replaces Bootstrap 3) ── */
.list-group { padding-left: 0; margin-bottom: 20px; list-style: none; }
.facet, .facet-active { margin-bottom: 0; }

/* CRITICAL: must use display:table, NOT flexbox.
   show_facets.js renders a colored proportion bar as a <div> immediately
   after each <button> inside .input-group. With display:table, they stack
   vertically (each becomes a table row). With display:flex, the bar becomes
   a horizontal sibling and disappears entirely. */
.input-group { position: relative; display: table; border-collapse: separate; width: 100%; }
.input-group .form-control { display: table-cell; width: 100%; }
.input-group-btn { display: table-cell; white-space: nowrap; width: 1%; vertical-align: middle; }
.form-control {
  display: block; width: 100%;
  padding: 4px 8px; font-size: 14px; line-height: 1.43;
  color: #555; background: #fff;
  border: 1px solid #ccc; border-radius: 4px;
}
.form-control:focus { outline: none; border-color: #66afe9; }

.btn {
  display: inline-block; padding: 5px 10px;
  font-size: 14px; font-weight: 400; line-height: 1.43;
  text-align: center; white-space: nowrap; vertical-align: middle;
  cursor: pointer; border: 1px solid transparent; border-radius: 4px;
  background: none; font-family: inherit;
}
.btn-block  { display: block; width: 100%; }
.btn-primary { color: #fff; background: #337ab7; border-color: #2e6da4; }
.btn-default { color: #333; background: #fff; border-color: #ccc; }
.btn-default:hover { background: #e6e6e6; border-color: #adadad; }
.badge {
  display: inline-block; min-width: 10px; padding: 3px 7px;
  font-size: 12px; font-weight: 700; line-height: 1;
  color: #fff; text-align: center; white-space: nowrap;
  vertical-align: baseline; background: #777; border-radius: 10px;
}
.pull-right { float: right !important; }
```

## Tooltip styling on dark basemaps

The correct approach is to style the tooltip **inside the template itself** using inline styles on a wrapper `<div>`. Do NOT rely on `#tooltip { background: ... !important }` CSS overrides — they are unreliable because ixMaps controls `#tooltip` visibility and may override your rules.

**Working pattern** (background + text color all in the template):

```javascript
.meta({ tooltip: [
  '<div style="padding:10px 13px;min-width:200px;font-family:sans-serif;line-height:1.6;',
  'background:rgba(15,23,42,0.95);border:1px solid rgba(148,163,184,0.2);border-radius:6px">',
  '<div style="font-weight:700;font-size:13px;color:#e2e8f0;margin-bottom:4px">{{title}}</div>',
  '<div style="font-size:12px;color:#cbd5e1">{{field}}</div>',
  '</div>'
].join('') })

## Tooltip and context menu fix

ixmaps creates `#tooltip` and `#contextmenu` with `class="hidden visibility-hidden;"` (note: literal semicolon in the class attribute). Always add this safety fix in `myMap.then()`:

```javascript
myMap.then(function() {
    setTimeout(function() {
        ["tooltip","contextmenu"].forEach(function(id) {
            var el = document.getElementById(id);
            if (el) {
                el.classList.remove("hidden");
                el.classList.remove("visibility-hidden");
                el.style.display = "none";
            }
        });
    }, 500);
});
```

## Fallback: CSS attribute-selector workaround

If Bootstrap cannot be removed (e.g. it is required by other page content), use higher-specificity rules to override the conflict. Specificity (0,2,0) beats Bootstrap's (0,1,0):

```css
.hidden[style*="display: flex"],   .hidden[style*="display:flex"]   { display: flex   !important; }
.hidden[style*="display: block"],  .hidden[style*="display:block"]  { display: block  !important; }
.hidden[style*="display: inline"], .hidden[style*="display:inline"] { display: inline !important; }
```

> Note: CDN-loaded Bootstrap stylesheets are CORS-blocked, so JS-based patching of `cssRules` does not work. The CSS or JS approaches above are the only reliable fixes.
