#!/bin/zsh

# Syncs settings that cannot be symlinked because the app owns them and writes
# them back: GUI apps whose settings live only in a `defaults` domain, and
# config files an app rewrites from its own UI. Only the keys listed below are
# snapshotted, so the rest of the app's state stays on this machine.

DOTFILES_DIR="${0:A:h}"
source "$DOTFILES_DIR/scripts/utils.sh"

PREFS_DIR="$DOTFILES_DIR/prefs"
# The snapshot as of the last successful export or import. It is what tells a
# local edit apart from a snapshot that arrived newer via git, so it stays out
# of the repo - every machine has its own. The path predates the rename to
# sync.sh and is kept so existing baselines stay valid.
BASELINE_DIR="$HOME/Library/Application Support/dotfiles/prefs"

# <defaults domain>:<process name to quit before importing>[:<app name to
# reopen, when it differs from the process name>]
DOMAINS=(
  "com.knollsoft.Rectangle:Rectangle"
  "pl.maketheweb.cleanshotx:CleanShot X"
  "com.lwouis.alt-tab-macos:AltTab"
  "com.superlogical.rex:Rex"
)

# <name>:<toml|json>:<config the app owns>:<snapshot, relative to the repo>
FILES=(
  "codex:toml:$HOME/.codex/config.toml:codex/config.toml"
  "claude:json:$HOME/.claude/settings.json:claude/settings.json"
)

# Keys that must never reach a snapshot because the repo is public. The
# allowlists below already exclude them; this guards against a careless glob.
SECRETS=(
  "activationKey"
)

# The keys worth carrying to a new machine, one pattern per line in
# prefs/keys/<name>.track. Anything not listed - window positions, updater
# state, usage counters, license keys - stays behind and the app falls back to
# its own default.
keeps_for() {
  read_keys "$PREFS_DIR/keys/$1.track"
}

read_keys() {
  [[ -f "$1" ]] && grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$1"
}

# Keeps only the allowlisted keys and writes a sorted XML plist so diffs stay
# readable. Aborts if a secret slips through, and warns about a pattern that
# matched nothing - that means the app renamed or dropped the key.
select_keys() {
  local src="$1" dst="$2" secret_count="$3"
  shift 3
  python3 - "$src" "$dst" "$secret_count" "$@" <<'PY'
import fnmatch, os, plistlib, sys

src, dst, secret_count = sys.argv[1], sys.argv[2], int(sys.argv[3])
rest = sys.argv[4:]
secrets, patterns = rest[:secret_count], rest[secret_count:]

with open(src, "rb") as f:
    data = plistlib.load(f)

kept = {k: v for k, v in data.items()
        if any(fnmatch.fnmatch(k, p) for p in patterns)}

# A path under this machine's home is stored as "~/..." so it still resolves
# on a machine with a different user name.
home = os.path.expanduser("~")
kept = {k: f"~{v[len(home):]}" if isinstance(v, str) and (v == home or v.startswith(home + "/")) else v
        for k, v in kept.items()}

leaked = [k for k in kept if any(fnmatch.fnmatch(k, s) for s in secrets)]
if leaked:
    sys.exit(f"secret key matched the allowlist: {', '.join(leaked)}")

unmatched = [p for p in patterns if not any(fnmatch.fnmatch(k, p) for k in data)]
if unmatched:
    print(f"no key matched: {', '.join(unmatched)}", file=sys.stderr)

with open(dst, "wb") as f:
    plistlib.dump(kept, f, sort_keys=True)

print(f"{len(data)} -> {len(kept)}")
PY
}

# The counterpart of select_keys for config files. Both formats are filtered as
# JSON; dasel converts TOML at either end because the system python has none,
# and it reads stdin unless that is closed.
select_file_keys() {
  local format="$1" src="$2" dst="$3"
  shift 3

  case "$format" in
    toml)
      dasel -i toml -o json --var f="toml:file:$src" '$f' </dev/null >"$dst.raw.json" || return 1
      ;;
    json)
      cp "$src" "$dst.raw.json" || return 1
      ;;
  esac

  python3 - "$dst.raw.json" "$dst.kept.json" "$@" <<'PY' || return 1
import json, sys

src, dst = sys.argv[1], sys.argv[2]
paths = sys.argv[3:]

with open(src) as f:
    data = json.load(f)

def leaves(node):
    return sum(leaves(v) if isinstance(v, dict) else 1 for v in node.values())

kept, missing = {}, []
for path in paths:
    parts = path.split(".")
    node = data
    for part in parts:
        if not isinstance(node, dict) or part not in node:
            node = None
            break
        node = node[part]
    if node is None:
        missing.append(path)
        continue
    target = kept
    for part in parts[:-1]:
        target = target.setdefault(part, {})
    target[parts[-1]] = node

if missing:
    print(f"no key matched: {', '.join(missing)}", file=sys.stderr)

with open(dst, "w") as f:
    json.dump(kept, f, sort_keys=True)

print(f"{leaves(data)} -> {leaves(kept)}")
PY

  from_json "$format" "$dst.kept.json" "$dst"
}

to_json() {
  local format="$1" src="$2" dst="$3"
  case "$format" in
    toml) dasel -i toml -o json --var f="toml:file:$src" '$f' </dev/null >"$dst" ;;
    json) cp "$src" "$dst" ;;
  esac
}

from_json() {
  local format="$1" src="$2" dst="$3"
  case "$format" in
    toml) dasel -i json -o toml --var f="json:file:$src" '$f' </dev/null >"$dst" ;;
    json) jq -S '.' "$src" >"$dst" ;;
  esac
}

# Compares the baseline, the snapshot and the live settings key by key. A key
# that moved on one side only takes that side's value; a key that moved on both
# sides to different values is a conflict and is left alone on both. Export
# carries this machine's edits into the snapshot, import carries the
# snapshot's into the app. Config files are compared leaf by leaf, as JSON.
#
# Writes into <out>: snapshot.<kind> (export, when it changed), apply.<kind>
# and deletes (import, the values to write into the app), baseline.<kind>, and
# report, one line per finding with errors marked "!".
merge_keys() {
  python3 - "$@" <<'PY'
import json, os, plistlib, sys

mode, kind, base_path, snap_path, live_path, out = sys.argv[1:7]
MISSING = object()

def load(path):
    with open(path, "rb") as f:
        return plistlib.load(f) if kind == "plist" else json.load(f)

def flatten(node, prefix=()):
    flat = {}
    for k, v in node.items():
        if kind == "json" and isinstance(v, dict) and v:
            flat.update(flatten(v, prefix + (k,)))
        else:
            flat[prefix + (k,)] = v
    return flat

def unflatten(flat):
    root = {}
    for path, v in flat.items():
        node = root
        for part in path[:-1]:
            node = node.setdefault(part, {})
        node[path[-1]] = v
    return root

def dump(flat, name):
    path = os.path.join(out, f"{name}.{kind}")
    if kind == "plist":
        with open(path, "wb") as f:
            plistlib.dump(unflatten(flat), f, sort_keys=True)
    else:
        with open(path, "w") as f:
            json.dump(unflatten(flat), f, sort_keys=True)

# Strict, so that 1 and True or 14 and 14.0 count as different values.
def same(a, b):
    return a is b or (type(a) is type(b) and a == b)

def put(flat, key, value):
    if value is MISSING:
        flat.pop(key, None)
    else:
        flat[key] = value

def show(value):
    if value is MISSING:
        return "(unset)"
    text = json.dumps(value, ensure_ascii=False, default=str)
    return text if len(text) <= 80 else text[:77] + "..."

def name(key):
    return ".".join(key)

snap, live = flatten(load(snap_path)), flatten(load(live_path))
# With no baseline yet nothing counts as an edit made here, so the snapshot
# wins: a machine that has pulled but not imported must not export stale values.
base = flatten(load(base_path)) if os.path.exists(base_path) else dict(live)
keys = sorted(base.keys() | snap.keys() | live.keys())

ours, theirs, conflicts = [], [], []
for key in keys:
    b, s, l = (d.get(key, MISSING) for d in (base, snap, live))
    if same(s, l):
        continue
    if same(s, b):
        ours.append(key)
    elif same(l, b):
        theirs.append(key)
    else:
        conflicts.append(key)

new_snap, new_live = dict(snap), dict(live)
report, kept = [], []
if mode == "export":
    for key in ours:
        put(new_snap, key, live.get(key, MISSING))
    if ours:
        dump(new_snap, "snapshot")
        report.append(f"exported {', '.join(map(name, ours))}")
    if theirs:
        report.append(f"newer in the snapshot, run ./sync.sh import: {', '.join(map(name, theirs))}")
else:
    apply, deletes = {}, []
    for key in theirs:
        value = snap.get(key, MISSING)
        if value is MISSING and kind == "json":
            kept.append(key)
            continue
        put(new_live, key, value)
        if value is MISSING:
            deletes.append(key)
        else:
            if kind == "plist" and isinstance(value, str) and (value == "~" or value.startswith("~/")):
                value = os.path.expanduser(value)
            apply[key] = value
    if apply:
        dump(apply, "apply")
    if deletes:
        with open(os.path.join(out, "deletes"), "w") as f:
            f.writelines(name(k) + "\n" for k in deletes)
    applied = [k for k in theirs if k not in kept]
    if applied:
        report.append(f"imported {', '.join(map(name, applied))}")
    if ours:
        report.append(f"changed here, run ./sync.sh export: {', '.join(map(name, ours))}")
    if kept:
        report.append(f"! removed from the snapshot but left in the config: {', '.join(map(name, kept))}")

for key in conflicts:
    report.append(f"! both changed {name(key)}: snapshot {show(snap.get(key, MISSING))}, "
                  f"this machine {show(live.get(key, MISSING))}")

# A key is settled once both sides agree; until then the baseline keeps its old
# value, so the side that moved is still recognized on the next run.
new_base = {}
for key in keys:
    s, l = new_snap.get(key, MISSING), new_live.get(key, MISSING)
    put(new_base, key, s if same(s, l) else base.get(key, MISSING))
dump(new_base, "baseline")

with open(os.path.join(out, "report"), "w") as f:
    f.writelines(line + "\n" for line in report)
PY
}

# Runs merge_keys on a plist or a config file and prints its report. Sets
# REPLY to the directory holding the output, converted back to <format>.
three_way() {
  local mode="$1" format="$2" baseline="$3" snapshot="$4" live="$5" counts="$6"
  local dir kind=plist line f
  dir=$(mktemp -d "$tmp/merge.XXXXXX")

  if [[ "$format" != plist ]]; then
    kind=json
    mkdir "$dir/in"
    to_json "$format" "$snapshot" "$dir/in/snapshot.json" || return 1
    to_json "$format" "$live" "$dir/in/live.json" || return 1
    if [[ -f "$baseline" ]]; then
      to_json "$format" "$baseline" "$dir/in/baseline.json" || return 1
    fi
    baseline="$dir/in/baseline.json" snapshot="$dir/in/snapshot.json" live="$dir/in/live.json"
  fi

  mkdir "$dir/out"
  merge_keys "$mode" "$kind" "$baseline" "$snapshot" "$live" "$dir/out" || return 1

  for f in snapshot apply baseline; do
    [[ -f "$dir/out/$f.$kind" ]] || continue
    if [[ "$kind" == plist ]]; then
      mv "$dir/out/$f.plist" "$dir/$f.plist"
    else
      from_json "$format" "$dir/out/$f.json" "$dir/$f.$format" || return 1
    fi
  done
  [[ -f "$dir/out/deletes" ]] && mv "$dir/out/deletes" "$dir/deletes"

  if [[ ! -s "$dir/out/report" ]]; then
    print_step "unchanged ($counts keys)"
  fi
  while IFS= read -r line; do
    if [[ "$line" == '!'* ]]; then
      print_error "${line#! }"
    else
      print_step "$line"
    fi
  done <"$dir/out/report"

  REPLY="$dir"
}

export_snapshot() {
  local format="$1" live="$2" snapshot="$3" baseline="$4" counts="$5"

  if [[ ! -f "$snapshot" ]]; then
    cp "$live" "$snapshot"
    cp "$live" "$baseline"
    print_step "created ($counts keys)"
    return
  fi

  if ! three_way export "$format" "$baseline" "$snapshot" "$live" "$counts"; then
    print_error "Comparison failed, snapshot left untouched"
    return
  fi
  [[ -f "$REPLY/snapshot.$format" ]] && cp "$REPLY/snapshot.$format" "$snapshot"
  cp "$REPLY/baseline.$format" "$baseline"
}

cmd_export() {
  print_section "Export settings"
  mkdir -p "$PREFS_DIR" "$BASELINE_DIR"

  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT

  local entry domain name format config snapshot baseline raw live counts
  local -a keeps parts

  for entry in "${DOMAINS[@]}"; do
    domain="${entry%%:*}"
    snapshot="$PREFS_DIR/$domain.plist"
    baseline="$BASELINE_DIR/$domain.plist"
    raw="$tmp/$domain.plist"
    live="$tmp/live.plist"

    print_header "$domain"
    if ! defaults export "$domain" "$raw" 2>/dev/null; then
      print_error "Domain not found - is the app installed?"
      continue
    fi

    keeps=(${(f)"$(keeps_for "$domain")"})
    if (( ${#keeps} == 0 )); then
      print_error "No allowlist defined for $domain"
      continue
    fi

    if ! counts=$(select_keys "$raw" "$live" "${#SECRETS[@]}" "${SECRETS[@]}" "${keeps[@]}"); then
      print_error "Selection failed, snapshot left untouched"
      continue
    fi

    export_snapshot plist "$live" "$snapshot" "$baseline" "$counts"
  done

  for entry in "${FILES[@]}"; do
    parts=("${(@s.:.)entry}")
    name="${parts[1]}"
    format="${parts[2]}"
    config="${parts[3]}"
    snapshot="$DOTFILES_DIR/${parts[4]}"
    baseline="$BASELINE_DIR/$name.$format"
    live="$tmp/$name.$format"

    print_header "$name"
    if [[ ! -f "$config" ]]; then
      print_error "No config at $config - is the app installed?"
      continue
    fi

    keeps=(${(f)"$(keeps_for "$name")"})
    if (( ${#keeps} == 0 )); then
      print_error "No allowlist defined for $name"
      continue
    fi

    if ! counts=$(select_file_keys "$format" "$config" "$live" "${keeps[@]}"); then
      print_error "Selection failed, snapshot left untouched"
      continue
    fi

    export_snapshot "$format" "$live" "$snapshot" "$baseline" "$counts"
  done

  print_success "Export complete"
}

# Writes only the keys the snapshot moved since the baseline, so an edit made
# on this machine and not yet exported survives. An app is quit and reopened
# only when one of its keys is written. Unmatched-key warnings are silenced:
# a key the snapshot is about to bring is expected to be missing here.
cmd_import() {
  print_section "Import settings"

  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT

  mkdir -p "$BASELINE_DIR"

  local entry domain process app snapshot baseline raw live counts dir key
  local -a keeps
  for entry in "${DOMAINS[@]}"; do
    domain="${entry%%:*}"
    app="${entry#*:}"
    process="${app%%:*}"
    app="${app#*:}"
    snapshot="$PREFS_DIR/$domain.plist"
    baseline="$BASELINE_DIR/$domain.plist"
    raw="$tmp/$domain.plist"
    live="$tmp/live.plist"

    print_header "$app"
    if [[ ! -f "$snapshot" ]]; then
      print_error "No snapshot at $snapshot"
      continue
    fi

    keeps=(${(f)"$(keeps_for "$domain")"})
    if (( ${#keeps} == 0 )); then
      print_error "No allowlist defined for $domain"
      continue
    fi

    # An app that has never run has no domain yet.
    defaults export "$domain" "$raw" 2>/dev/null || plutil -create xml1 "$raw"
    if ! counts=$(select_keys "$raw" "$live" "${#SECRETS[@]}" "${SECRETS[@]}" "${keeps[@]}" 2>/dev/null); then
      print_error "Selection failed, nothing imported"
      continue
    fi

    if ! three_way import plist "$baseline" "$snapshot" "$live" "$counts"; then
      print_error "Comparison failed, nothing imported"
      continue
    fi
    dir="$REPLY"

    if [[ -f "$dir/apply.plist" || -f "$dir/deletes" ]]; then
      # A running app holds its own copy of the domain and writes it back on
      # quit, which would undo the import. `defaults import` merges into the
      # domain, so the app's own state - license included - stays.
      killall "$process" 2>/dev/null
      if [[ -f "$dir/apply.plist" ]] && ! defaults import "$domain" "$dir/apply.plist"; then
        print_error "Failed to import $domain"
        continue
      fi
      if [[ -f "$dir/deletes" ]]; then
        while IFS= read -r key; do
          defaults delete "$domain" "$key"
        done <"$dir/deletes"
      fi
      open -a "$app" 2>/dev/null
    fi
    cp "$dir/baseline.plist" "$baseline"
  done

  local name format config merged
  local -a parts
  for entry in "${FILES[@]}"; do
    parts=("${(@s.:.)entry}")
    name="${parts[1]}"
    format="${parts[2]}"
    config="${parts[3]}"
    snapshot="$DOTFILES_DIR/${parts[4]}"
    baseline="$BASELINE_DIR/$name.$format"
    live="$tmp/$name.$format"
    merged="$tmp/$name.merged.$format"

    print_header "$name"
    if [[ ! -f "$snapshot" ]]; then
      print_error "No snapshot at $snapshot"
      continue
    fi

    if [[ ! -f "$config" ]]; then
      mkdir -p "${config:h}"
      cp "$snapshot" "$config" && cp "$snapshot" "$baseline"
      print_step "created $config"
      continue
    fi

    keeps=(${(f)"$(keeps_for "$name")"})
    if (( ${#keeps} == 0 )); then
      print_error "No allowlist defined for $name"
      continue
    fi

    if ! counts=$(select_file_keys "$format" "$config" "$live" "${keeps[@]}" 2>/dev/null); then
      print_error "Selection failed, nothing imported"
      continue
    fi

    if ! three_way import "$format" "$baseline" "$snapshot" "$live" "$counts"; then
      print_error "Comparison failed, nothing imported"
      continue
    fi
    dir="$REPLY"

    # Merged into the config rather than replacing it: the rest of the file is
    # the app's own state.
    if [[ -f "$dir/apply.$format" ]]; then
      case "$format" in
        toml)
          dasel -i toml -o toml --unstable \
            --var current="toml:file:$config" \
            --var managed="toml:file:$dir/apply.toml" \
            'merge($current, $managed)' </dev/null >"$merged"
          ;;
        json)
          jq -s '.[0] * .[1]' "$config" "$dir/apply.json" >"$merged"
          ;;
      esac
      if (( $? != 0 )) || ! mv "$merged" "$config"; then
        print_error "Failed to write $config"
        continue
      fi
    fi
    cp "$dir/baseline.$format" "$baseline"
  done

  print_success "Import complete"
}

# Settings outside the allowlists are compared against a full copy of each
# app's settings, kept per machine next to the baselines. Only --accept moves
# that copy, so changes pile up until they have been reviewed and none slip by
# between reviews.
cmd_changes() {
  local accept="$1"

  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  mkdir -p "$BASELINE_DIR"

  local entry name format config now
  local -a parts copies
  for entry in "${DOMAINS[@]}"; do
    name="${entry%%:*}"
    now="$tmp/$name.plist"
    defaults export "$name" "$now" 2>/dev/null &&
      copies+=("$name" plist "$now" "$BASELINE_DIR/$name.full.plist")
  done
  for entry in "${FILES[@]}"; do
    parts=("${(@s.:.)entry}")
    name="${parts[1]}"
    format="${parts[2]}"
    config="${parts[3]}"
    now="$tmp/$name.json"
    [[ -f "$config" ]] || continue
    case "$format" in
      toml) dasel -i toml -o json --var f="toml:file:$config" '$f' </dev/null >"$now" ;;
      json) cp "$config" "$now" ;;
    esac && copies+=("$name" json "$now" "$BASELINE_DIR/$name.full.json")
  done

  if [[ "$accept" == "--accept" ]]; then
    local kind previous
    for name kind now previous in "${copies[@]}"; do
      cp "$now" "$previous"
    done
    print_success "Accepted the current settings"
    return
  fi

  python3 - "$PREFS_DIR/keys" "${copies[@]}" <<'PY'
import fnmatch, hashlib, json, os, plistlib, sys

keys_dir, rest = sys.argv[1], sys.argv[2:]

def load(path, kind):
    with open(path, "rb") as f:
        return plistlib.load(f) if kind == "plist" else json.load(f)

# A file's allowlist names dotted paths into nested tables, so a file is
# compared leaf by leaf; a tracked path also covers everything under it.
def flatten(node, prefix=""):
    out = {}
    for k, v in node.items():
        path = f"{prefix}{k}"
        if isinstance(v, dict) and v:
            out.update(flatten(v, path + "."))
        else:
            out[path] = v
    return out

def tracked(name):
    path = os.path.join(keys_dir, f"{name}.track")
    if not os.path.exists(path):
        return []
    with open(path) as f:
        return [l.strip() for l in f if l.strip() and not l.lstrip().startswith("#")]

def show(value):
    if value is None:
        return "(unset)"
    if isinstance(value, bytes):
        return f"<{len(value)} bytes, sha1 {hashlib.sha1(value).hexdigest()[:8]}>"
    text = json.dumps(value, ensure_ascii=False, default=str)
    return text if len(text) <= 120 else text[:117] + "..."

changes = {}
for i in range(0, len(rest), 4):
    name, kind, now_path, prev_path = rest[i:i + 4]
    if not os.path.exists(prev_path):
        print(f"{name}: nothing to compare with - run ./sync.sh changes --accept",
              file=sys.stderr)
        continue
    now, prev = load(now_path, kind), load(prev_path, kind)
    if kind == "json":
        now, prev = flatten(now), flatten(prev)
    patterns = tracked(name)

    def listed(key):
        return any(fnmatch.fnmatch(key, p) or key.startswith(p + ".") for p in patterns)

    changed = {k: {"before": show(prev.get(k)), "after": show(now.get(k))}
               for k in sorted(now.keys() | prev.keys())
               if not listed(k) and now.get(k) != prev.get(k)}
    if changed:
        changes[name] = changed

print(json.dumps(changes, indent=2, ensure_ascii=False))
PY
}

case "${1:-}" in
  export)        cmd_export ;;
  import)        cmd_import ;;
  changes)       cmd_changes "${2:-}" ;;
  *)
    echo "Usage: ./sync.sh <export|import|changes [--accept]>"
    echo
    echo "  export         Snapshot app-owned settings into the repo"
    echo "  import         Apply the snapshots to this machine"
    echo "  changes        Print untracked settings changed since the last accept"
    echo "    --accept     Take the current settings as the new starting point"
    exit 1
    ;;
esac
