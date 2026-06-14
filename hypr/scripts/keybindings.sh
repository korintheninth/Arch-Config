#!/usr/bin/env bash

config_file="${HOME}/.config/hypr/conf/keybinding.lua"

keybinds=$(python3 - "$config_file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

main_mod = "SUPER"
hypr_scripts = "~/.config/hypr/scripts"

if m := re.search(r'local var_mainMod = "([^"]+)"', text):
    main_mod = m.group(1)
if m := re.search(r'local var_HYPRSCRIPTS = "([^"]+)"', text):
    hypr_scripts = m.group(1)


def skip_string(s, i):
    quote = s[i]
    i += 1
    while i < len(s):
        if s[i] == "\\":
            i += 2
            continue
        if s[i] == quote:
            return i + 1
        i += 1
    return i


def split_top_level(s):
    parts = []
    start = 0
    depth = 0
    i = 0
    while i < len(s):
        c = s[i]
        if c in "\"'":
            i = skip_string(s, i)
            continue
        if c in "({[":
            depth += 1
        elif c in ")}]":
            depth -= 1
        elif c == "," and depth == 0:
            parts.append(s[start:i].strip())
            start = i + 1
        i += 1
    parts.append(s[start:].strip())
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], ",".join(parts[1:])


def expand_lua_strings(expr):
    expr = re.sub(r"var_mainMod\s*\.\.\s*", f'"{main_mod}" .. ', expr)
    expr = re.sub(r"var_HYPRSCRIPTS\s*\.\.\s*", f'"{hypr_scripts}" .. ', expr)

    chunks = []
    remaining = expr.strip()
    while remaining:
        remaining = remaining.lstrip()
        if remaining.startswith('"') or remaining.startswith("'"):
            end = skip_string(remaining, 0)
            quote = remaining[0]
            chunks.append(remaining[1 : end - 1].replace("\\" + quote, quote))
            remaining = remaining[end:].lstrip()
            if remaining.startswith(".."):
                remaining = remaining[2:].lstrip()
            else:
                break
        else:
            break

    if chunks:
        return "".join(chunks).strip()
    return expr.strip().strip("\"'")


def describe_action(action):
    action = re.sub(r"\s+", " ", action.strip())

    if m := re.search(r"hl\.dsp\.exec_cmd\((.+)\)\s*$", action):
        cmd = expand_lua_strings(m.group(1))
        return cmd.replace(hypr_scripts, "~/.config/hypr/scripts")

    if m := re.search(r"hl\.dsp\.window\.(\w+)\((.*)\)\s*$", action):
        name, args = m.group(1), m.group(2).strip()
        if name == "close":
            return "killactive"
        if name == "float":
            return "togglefloating"
        if name == "fullscreen":
            return "fullscreen"
        if "direction" in args:
            d = re.search(r'direction = "([^"]+)"', args)
            return f"{name.replace('_', ' ')} {d.group(1) if d else ''}".strip()
        if "workspace" in args:
            w = re.search(r'workspace = "?([^",}]+)"?', args)
            return f"move to workspace {w.group(1) if w else ''}".strip()
        return name.replace("_", " ")

    if m := re.search(r"hl\.dsp\.focus\((.*)\)\s*$", action):
        args = m.group(1)
        if d := re.search(r'direction = "([^"]+)"', args):
            return f"movefocus {d.group(1)}"
        if w := re.search(r'workspace = "?([^",}]+)"?', args):
            return f"workspace {w.group(1)}"

    if m := re.search(r'hl\.dsp\.layout\("([^"]+)"\)\s*$', action):
        return m.group(1)

    if m := re.search(r"hl\.dsp\.group\.(\w+)\(\)\s*$", action):
        return f"group {m.group(1)}"

    cleaned = re.sub(r"^hl\.dsp\.", "", action)
    cleaned = re.sub(r"\(\)$", "", cleaned)
    return cleaned.replace(".", " ")


def extract_bind_calls(source):
    calls = []
    i = 0
    while True:
        idx = source.find("hl.bind(", i)
        if idx == -1:
            break

        start = idx + len("hl.bind(")
        depth = 1
        j = start
        while j < len(source) and depth:
            c = source[j]
            if c in "\"'":
                j = skip_string(source, j)
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            j += 1

        calls.append(source[start : j - 1])
        i = j
    return calls


lines = []
for call in extract_bind_calls(text):
    key_expr, rest = split_top_level(call)
    action_expr, _ = split_top_level(rest) if rest else ("", "")

    keys = expand_lua_strings(key_expr)
    action = describe_action(action_expr)
    lines.append(f"{keys}\r{action}")

print("\n".join(lines))
PY
)

sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" -config ~/.config/rofi/config-compact.rasi <<<"$keybinds"
