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

  case "$format" in
    toml)
      dasel -i json -o toml --var f="json:file:$dst.kept.json" '$f' </dev/null >"$dst"
      ;;
    json)
      jq -S '.' "$dst.kept.json" >"$dst"
      ;;
  esac
}

# Undoes the export-side rewrite: "~/..." becomes this machine's home.
expand_paths() {
  python3 - "$1" "$2" <<'PY'
import os, plistlib, sys

with open(sys.argv[1], "rb") as f:
    data = plistlib.load(f)

data = {k: os.path.expanduser(v) if isinstance(v, str) and (v == "~" or v.startswith("~/")) else v
        for k, v in data.items()}

with open(sys.argv[2], "wb") as f:
    plistlib.dump(data, f, sort_keys=True)
PY
}

# Compares the live settings, the snapshot and the baseline. Only a change made
# on this machine is written back; a snapshot that moved ahead of the baseline
# came from another machine and must not be overwritten with stale values.
sync_snapshot() {
  local live="$1" snapshot="$2" baseline="$3" counts="$4"

  if [[ ! -f "$snapshot" ]]; then
    cp "$live" "$snapshot"
    cp "$live" "$baseline"
    print_step "created ($counts keys)"
    return
  fi

  # Seeding from the live settings rather than the snapshot: on a machine that
  # has pulled but not imported, seeding from the snapshot would read the stale
  # live values as a local edit and export them over the newer ones.
  [[ -f "$baseline" ]] || cp "$live" "$baseline"

  if cmp -s "$live" "$baseline"; then
    if cmp -s "$snapshot" "$baseline"; then
      print_step "unchanged ($counts keys)"
    else
      print_step "skipped - snapshot is newer, run ./sync.sh import"
    fi
    return
  fi

  # Both moved to the same values, e.g. an edit made in the repo and the app.
  if cmp -s "$live" "$snapshot"; then
    cp "$live" "$baseline"
    print_step "unchanged ($counts keys)"
    return
  fi

  if ! cmp -s "$snapshot" "$baseline"; then
    print_error "skipped - the snapshot and this machine both changed"
    return
  fi

  cp "$live" "$snapshot"
  cp "$live" "$baseline"
  print_step "updated ($counts keys)"
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

    sync_snapshot "$live" "$snapshot" "$baseline" "$counts"
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

    sync_snapshot "$live" "$snapshot" "$baseline" "$counts"
  done

  print_success "Export complete"
}

cmd_import() {
  print_section "Import settings"

  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT

  mkdir -p "$BASELINE_DIR"

  local entry domain process app snapshot baseline
  for entry in "${DOMAINS[@]}"; do
    domain="${entry%%:*}"
    app="${entry#*:}"
    process="${app%%:*}"
    app="${app#*:}"
    snapshot="$PREFS_DIR/$domain.plist"
    baseline="$BASELINE_DIR/$domain.plist"

    print_header "$app"
    if [[ ! -f "$snapshot" ]]; then
      print_error "No snapshot at $snapshot"
      continue
    fi

    # A running app holds its own copy of the domain and writes it back on quit,
    # which would undo the import.
    print_step "Quitting $app"
    killall "$process" 2>/dev/null

    # Merge rather than replace: the snapshot holds only the curated keys, and
    # `defaults import` would otherwise wipe the app's own state, license included.
    if ! expand_paths "$snapshot" "$tmp/expanded.plist"; then
      print_error "Failed to read $snapshot"
      continue
    fi

    if defaults import "$domain" "$tmp/expanded.plist"; then
      cp "$snapshot" "$baseline"
      print_step "Imported $domain"
      open -a "$app" 2>/dev/null
    else
      print_error "Failed to import $domain"
    fi
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
    merged="$tmp/$name.$format"

    print_header "$name"
    if [[ ! -f "$snapshot" ]]; then
      print_error "No snapshot at $snapshot"
      continue
    fi

    # Merge rather than replace, for the same reason as the plists above: the
    # snapshot holds only the curated keys and the rest of the file is the
    # app's own state. A managed key the repo drops is not removed here, only
    # left at whatever the app last wrote.
    if [[ -f "$config" ]]; then
      case "$format" in
        toml)
          dasel -i toml -o toml --unstable \
            --var current="toml:file:$config" \
            --var managed="toml:file:$snapshot" \
            'merge($current, $managed)' </dev/null >"$merged"
          ;;
        json)
          jq -s '.[0] * .[1]' "$config" "$snapshot" >"$merged"
          ;;
      esac
      if (( $? != 0 )); then
        print_error "Failed to merge $snapshot"
        continue
      fi
    else
      mkdir -p "${config:h}"
      cp "$snapshot" "$merged"
    fi

    if mv "$merged" "$config"; then
      cp "$snapshot" "$baseline"
      print_step "Imported $name"
    else
      print_error "Failed to write $config"
    fi
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
