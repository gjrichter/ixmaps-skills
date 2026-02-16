# Repository Overview

This repository provides ixMaps skills for different assistants plus templates and examples. In the subfolders you will find tool-specific skills for **Claude Code** and **Codex**. For chat usage, use the general `SKILL.md` described below.

This **skills** of this repository enable **AI assistant** to create **ixMaps maps** in **HTML documents**. This documents load the **`ixmaps-flat`** framework and are executable in any **HTML5**-capable browser.

This guide shows how to load the`SKILL.md` into a chat assistant and request ixMaps maps.



# Using SKILL.md in Chat

## 1) Load the skill into the chat

Pick one method:

### Method A: Share the raw GitHub URL
1. Paste this message into your chat:
```
Please read and follow the ixmaps skill specifications from:
https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md
```
2. Wait for confirmation that the skill is loaded.

### Method B: Upload the file
1. Download `SKILL.md` from the repository.
2. Upload it to your chat.
3. Say: "Please follow these specifications to create ixmaps."

### Method C: Copy/paste
1. Open `SKILL.md`.
2. Copy the full content.
3. Paste it into your chat and confirm the assistant should follow it.

## 2) Ask for a map

Start with a clear request and include data or a URL when possible:

```
Create a bubble map of Italian cities sized by population.
Use this data:
[{"name":"Rome","lat":41.9,"lon":12.5,"population":2873000},
 {"name":"Milan","lat":45.46,"lon":9.19,"population":1372000}]
```

## 3) Iterate

Refine the result with short follow-ups:

```
Change the base map to "CartoDB - Positron".
Make the bubbles 2x larger.
Use the tableau palette for categories.
```

## Tips

- Be explicit about field names (e.g., `lat`, `lon`, `population`).
- For GeoJSON/TopoJSON, specify the property field used for labeling or coloring.
- If the assistant doesn't follow the rules, re-share `SKILL.md` in the same chat.
