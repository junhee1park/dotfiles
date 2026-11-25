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

5. Run `./sync.sh export`. It writes the tracked keys into the snapshots,
   including changes to keys tracked earlier. Report any line that is not
   `unchanged`, `updated` or `created`:
   - `skipped - snapshot is newer`: another machine pushed newer values. Ask
     before running `./sync.sh import`, which quits and reopens the apps.
   - `the snapshot and this machine both changed`: show both sides and ask.
   - `no key matched`: a tracked key is gone or renamed; say which.

6. Once the user has answered for every key, run
   `./sync.sh changes --accept`. A skipped key comes up again only when it
   changes again. Never accept before the user has seen the changes.

7. Show what changed in the repo (`git status`, and the diff of
   `prefs/keys/`). Do not commit unless asked.
