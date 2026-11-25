---
name: sync-settings
description: Snapshot app-owned settings into the dotfiles repo, review the settings that changed outside the allowlists, and ask which to start syncing. Use when asked to sync settings or prefs, or to run sync.sh.
---

`sync.sh` at the root of the dotfiles repo this skill lives in syncs settings
that apps own and rewrite: `defaults` domains (`DOMAINS`) and config files
(`FILES`). Only the keys in `prefs/keys/<name>.track` are synced. Run every
command below from the repo root.

1. Run `./sync.sh changes`. It prints, as JSON, every key outside the
   allowlists that changed since the last accept. Plist keys are flat;
   config-file keys are dotted paths. When it reports nothing to compare
   with, this machine has no starting point yet: run
   `./sync.sh changes --accept`, say so, and skip to step 4.

2. Sort each key into one of three groups:
   - **Noise**: state the app writes by itself and nobody would choose to
     sync, such as update-check times, window frames and sizes, counters,
     caches, history and recent items, session or instance IDs, app versions,
     and paths into the app's own caches.
   - **Setting**: something a person chooses, in the app's UI or its config.
   - **Unknown**: you could not tell what it is.

   Base each call on evidence, not on the name alone: the value and how it
   changed, the app's docs or source, or the key's neighbors in the app
   binary (`strings <binary> | grep -n -C3 <key>`). A key you cannot place
   is Unknown, never Noise. A setting stays a Setting even when it changes
   often, such as a model picker.

3. Walk the user through the keys in small batches, in this order, and wait
   for an answer after each batch: Settings, then Unknown keys, then Noise.
   Number the items across all batches so the user can answer by number
   ("1 track, 2 skip"). Open each batch with its place in the review
   ("batch 2/3") and a one-line record of the answers so far.
   - A Setting or Unknown item: the app, the key, before → after, what it is
     and where that came from, and your recommendation (track or skip).
   - Noise: one numbered item per app listing its keys, each with a few
     words on what it is, so the user can pull one out.

   Skip a batch that has no keys. The user decides; never track a key on
   your own. Never offer a key that holds a secret or a license, and never
   add a pattern that would match one (`SECRETS` in `sync.sh`).

4. Append each key the user picked to `prefs/keys/<name>.track`, one per
   line. For a config file, write the dotted path of the leaf or table to
   sync.

5. Run `./sync.sh export`. Key by key, it writes into the snapshots what
   changed on this machine since the last sync, and leaves alone what changed
   in the snapshot. Report any line that is not `unchanged`, `exported` or
   `created`:
   - `newer in the snapshot`: another machine changed these keys. Ask before
     running `./sync.sh import`, which writes only those keys and quits and
     reopens each app it writes to. If the agent runs inside one of those
     apps, ask the user to run it from another terminal.
   - `both changed <key>`: both sides changed it to different values. Show
     both and ask which to keep. To keep this machine's value, set it in the
     snapshot file; to take the snapshot's, set it in the app. The next
     export sees both sides agree.
   - `no key matched`: a tracked key is gone or renamed, unless the same key
     is `newer in the snapshot` - then it is not imported yet. Say which.

6. Once the user has answered for every key, run
   `./sync.sh changes --accept`. A skipped key comes up again only when it
   changes again. Never accept before the user has seen the changes.

7. Show what changed in the repo (`git status`, and the diff of
   `prefs/keys/`). Do not commit unless asked.
