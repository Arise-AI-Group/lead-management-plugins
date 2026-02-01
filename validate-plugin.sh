#!/bin/bash
# validate-plugin.sh — Plugin validation for lead-management
# Runs structural, schema, cross-reference, and content checks.
# Exit 0 = all pass, Exit 1 = failures found.

set -uo pipefail

PLUGIN_DIR="lead-management"
PASS=0
FAIL=0
WARN=0

pass() {
  echo "  [PASS] $1"
  ((PASS++))
}

fail() {
  echo "  [FAIL] $1"
  ((FAIL++))
}

warn() {
  echo "  [WARN] $1"
  ((WARN++))
}

# Resolve script location so it works from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Lead Management Plugin Validation ==="
echo ""

# ─────────────────────────────────────────────
# 1. STRUCTURE CHECKS
# ─────────────────────────────────────────────
echo "--- Structure Checks ---"

# Required files
for f in \
  "$PLUGIN_DIR/.claude-plugin/plugin.json" \
  "$PLUGIN_DIR/.mcp.json" \
  "$PLUGIN_DIR/CONNECTORS.md" \
  "$PLUGIN_DIR/README.md" \
  "$PLUGIN_DIR/LICENSE" \
  "README.md" \
  "LICENSE"; do
  if [ -f "$f" ]; then
    pass "$f exists"
  else
    fail "$f is missing"
  fi
done

# Required directories
for d in "$PLUGIN_DIR/commands" "$PLUGIN_DIR/skills"; do
  if [ -d "$d" ]; then
    pass "$d/ directory exists"
  else
    fail "$d/ directory is missing"
  fi
done

# Every skill directory must have SKILL.md
if [ -d "$PLUGIN_DIR/skills" ]; then
  for skill_dir in "$PLUGIN_DIR/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    if [ -f "$skill_dir/SKILL.md" ]; then
      pass "Skill \"$skill_name\" has SKILL.md"
    else
      fail "Skill \"$skill_name\" is missing SKILL.md"
    fi
  done
fi

# Every command file must be .md
if [ -d "$PLUGIN_DIR/commands" ]; then
  for cmd_file in "$PLUGIN_DIR/commands"/*; do
    if [ -f "$cmd_file" ]; then
      if [[ "$cmd_file" == *.md ]]; then
        pass "Command \"$(basename "$cmd_file")\" is .md"
      else
        fail "Command \"$(basename "$cmd_file")\" is not a .md file"
      fi
    fi
  done
fi

echo ""

# ─────────────────────────────────────────────
# 2. JSON SCHEMA VALIDATION
# ─────────────────────────────────────────────
echo "--- JSON Validation ---"

# plugin.json
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
  if python3 -c "import json; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
    pass "plugin.json is valid JSON"

    # Required fields
    for field in name version description author; do
      if python3 -c "
import json, sys
data = json.load(open('$PLUGIN_JSON'))
if '$field' not in data:
    sys.exit(1)
" 2>/dev/null; then
        pass "plugin.json has required field: $field"
      else
        fail "plugin.json missing required field: $field"
      fi
    done

    # Name is kebab-case
    name=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['name'])" 2>/dev/null)
    if [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
      pass "plugin.json name \"$name\" is kebab-case"
    else
      fail "plugin.json name \"$name\" is not kebab-case"
    fi

    # Version is semver-like
    version=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])" 2>/dev/null)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      pass "plugin.json version \"$version\" is valid semver"
    else
      fail "plugin.json version \"$version\" is not valid semver"
    fi
  else
    fail "plugin.json is invalid JSON"
  fi
fi

# .mcp.json
MCP_JSON="$PLUGIN_DIR/.mcp.json"
if [ -f "$MCP_JSON" ]; then
  if python3 -c "import json; json.load(open('$MCP_JSON'))" 2>/dev/null; then
    pass ".mcp.json is valid JSON"

    # Check each server has type and url
    python3 -c "
import json, sys
data = json.load(open('$MCP_JSON'))
servers = data.get('mcpServers', {})
errors = []
for name, config in servers.items():
    if 'type' not in config:
        errors.append(f'Server \"{name}\" missing \"type\" field')
    if 'url' not in config:
        errors.append(f'Server \"{name}\" missing \"url\" field')
    elif not config['url'].startswith('http'):
        errors.append(f'Server \"{name}\" URL is not HTTP(S): {config[\"url\"]}')
if errors:
    for e in errors:
        print(f'MCPERR:{e}')
    sys.exit(1)
else:
    print(f'MCPOK:{len(servers)} servers validated')
" 2>/dev/null | while IFS= read -r line; do
      if [[ "$line" == MCPERR:* ]]; then
        fail "${line#MCPERR:}"
      elif [[ "$line" == MCPOK:* ]]; then
        pass ".mcp.json ${line#MCPOK:}"
      fi
    done
  else
    fail ".mcp.json is invalid JSON"
  fi
fi

echo ""

# ─────────────────────────────────────────────
# 3. CROSS-REFERENCE INTEGRITY
# ─────────────────────────────────────────────
echo "--- Cross-Reference Checks ---"

# Check Related Skills references resolve to actual directories
if [ -d "$PLUGIN_DIR/skills" ]; then
  for skill_file in "$PLUGIN_DIR/skills"/*/SKILL.md; do
    if [ -f "$skill_file" ]; then
      skill_name="$(basename "$(dirname "$skill_file")")"
      # Extract skill references from "Related Skills" section
      # Look for **skill-name** patterns after "## Related Skills"
      in_related=false
      while IFS= read -r line; do
        if [[ "$line" == "## Related Skills"* ]]; then
          in_related=true
          continue
        fi
        if [[ "$line" == "## "* ]] && [ "$in_related" = true ]; then
          break
        fi
        if [ "$in_related" = true ]; then
          # Match **skill-name** patterns
          refs=$(echo "$line" | grep -oP '\*\*\K[a-z-]+(?=\*\*)' 2>/dev/null || true)
          for ref in $refs; do
            if [ -d "$PLUGIN_DIR/skills/$ref" ]; then
              pass "Skill \"$skill_name\" → Related skill \"$ref\" exists"
            else
              fail "Skill \"$skill_name\" → Related skill \"$ref\" NOT FOUND"
            fi
          done
        fi
      done < "$skill_file"
    fi
  done
fi

# Check ~~placeholders are documented in CONNECTORS.md
CONNECTORS_FILE="$PLUGIN_DIR/CONNECTORS.md"
if [ -f "$CONNECTORS_FILE" ]; then
  connectors_content=$(cat "$CONNECTORS_FILE")

  # Collect all unique ~~placeholders from skills and commands
  # Use Python for reliable multi-word placeholder extraction
  # Matches ~~word (with hyphens), then optionally one more word for "~~conversation intelligence"
  # Strips trailing noise words like "connected", "is", "and", "or"
  all_placeholders=$(python3 -c "
import re, os, sys

noise = {'connected', 'is', 'are', 'and', 'or', 'the', 'a', 'to', 'for', 'in', 'on', 'at', 'by', 'with'}
found = set()
for root, dirs, files in os.walk('$PLUGIN_DIR/skills'):
    for f in files:
        with open(os.path.join(root, f)) as fh:
            for m in re.finditer(r'~~[a-zA-Z][a-zA-Z-]*(?:\s+[a-zA-Z-]+)*', fh.read()):
                parts = m.group().split()
                # Trim trailing noise words
                while len(parts) > 1 and parts[-1].lower() in noise:
                    parts.pop()
                found.add(' '.join(parts))
for root, dirs, files in os.walk('$PLUGIN_DIR/commands'):
    for f in files:
        with open(os.path.join(root, f)) as fh:
            for m in re.finditer(r'~~[a-zA-Z][a-zA-Z-]*(?:\s+[a-zA-Z-]+)*', fh.read()):
                parts = m.group().split()
                while len(parts) > 1 and parts[-1].lower() in noise:
                    parts.pop()
                found.add(' '.join(parts))
for p in sorted(found):
    print(p)
" 2>/dev/null || true)

  while IFS= read -r placeholder; do
    [ -z "$placeholder" ] && continue
    if echo "$connectors_content" | grep -qF "$placeholder"; then
      pass "Placeholder \"$placeholder\" documented in CONNECTORS.md"
    else
      fail "Placeholder \"$placeholder\" NOT documented in CONNECTORS.md"
    fi
  done <<< "$all_placeholders"
fi

# Check command filenames are referenced in plugin README
PLUGIN_README="$PLUGIN_DIR/README.md"
if [ -f "$PLUGIN_README" ]; then
  readme_content=$(cat "$PLUGIN_README")
  for cmd_file in "$PLUGIN_DIR/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
      cmd_name="$(basename "$cmd_file" .md)"
      if echo "$readme_content" | grep -q "$cmd_name"; then
        pass "Command \"$cmd_name\" referenced in plugin README"
      else
        fail "Command \"$cmd_name\" NOT referenced in plugin README"
      fi
    fi
  done

  # Check skill directory names are referenced in plugin README
  for skill_dir in "$PLUGIN_DIR/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    if echo "$readme_content" | grep -q "$skill_name"; then
      pass "Skill \"$skill_name\" referenced in plugin README"
    else
      fail "Skill \"$skill_name\" NOT referenced in plugin README"
    fi
  done
fi

echo ""

# ─────────────────────────────────────────────
# 4. CONTENT COMPLETENESS AUDIT
# ─────────────────────────────────────────────
echo "--- Content Completeness ---"

# Expected sections in SKILL.md files
SKILL_SECTIONS=("How It Works" "Getting Started" "Connectors" "Execution Flow" "Tips" "Related Skills")

for skill_file in "$PLUGIN_DIR/skills"/*/SKILL.md; do
  if [ -f "$skill_file" ]; then
    skill_name="$(basename "$(dirname "$skill_file")")"
    content=$(cat "$skill_file")

    # Check for H1 heading
    if echo "$content" | grep -qP '^# .+'; then
      pass "Skill \"$skill_name\" has H1 title"
    else
      fail "Skill \"$skill_name\" missing H1 title"
    fi

    # Check for expected sections
    for section in "${SKILL_SECTIONS[@]}"; do
      if echo "$content" | grep -qP "^## $section"; then
        pass "Skill \"$skill_name\" has \"## $section\""
      else
        # Some sections have variations (e.g., "Output Format" vs "Output Formats")
        if [ "$section" = "Connectors" ]; then
          if echo "$content" | grep -qP '^## Connectors'; then
            pass "Skill \"$skill_name\" has \"## Connectors\" (variant)"
          else
            fail "Skill \"$skill_name\" missing \"## $section\""
          fi
        else
          fail "Skill \"$skill_name\" missing \"## $section\""
        fi
      fi
    done
  fi
done

# Expected sections in command .md files
CMD_SECTIONS=("Usage" "How It Works" "What I Need" "Output" "If Connectors Available" "Tips")

for cmd_file in "$PLUGIN_DIR/commands"/*.md; do
  if [ -f "$cmd_file" ]; then
    cmd_name="$(basename "$cmd_file" .md)"
    content=$(cat "$cmd_file")

    # Check for H1 heading
    if echo "$content" | grep -qP '^# .+'; then
      pass "Command \"$cmd_name\" has H1 title"
    else
      fail "Command \"$cmd_name\" missing H1 title"
    fi

    # Check for expected sections
    for section in "${CMD_SECTIONS[@]}"; do
      if echo "$content" | grep -qi "^## .*$section"; then
        pass "Command \"$cmd_name\" has section matching \"$section\""
      else
        fail "Command \"$cmd_name\" missing section matching \"$section\""
      fi
    done
  fi
done

echo ""

# ─────────────────────────────────────────────
# 5. RELATIVE LINK VALIDATION
# ─────────────────────────────────────────────
echo "--- Link Validation ---"

# Check relative markdown links in all .md files
for md_file in $(find "$PLUGIN_DIR" -name "*.md" -type f); do
  rel_dir="$(dirname "$md_file")"
  # Extract relative links: [text](../path) or [text](./path)
  links=$(grep -oP '\[.*?\]\(\K\.\.?/[^)]+' "$md_file" 2>/dev/null || true)
  for link in $links; do
    # Strip any anchors
    link_path="${link%%#*}"
    resolved="$rel_dir/$link_path"
    if [ -e "$resolved" ]; then
      pass "Link in $(basename "$md_file"): \"$link_path\" resolves"
    else
      fail "Link in $(basename "$md_file"): \"$link_path\" BROKEN (from $rel_dir)"
    fi
  done
done

echo ""

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo "==========================================="
TOTAL=$((PASS + FAIL))
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
if [ "$WARN" -gt 0 ]; then
  echo "  Warnings: $WARN"
fi
echo "==========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  echo "  All checks passed!"
  exit 0
fi
