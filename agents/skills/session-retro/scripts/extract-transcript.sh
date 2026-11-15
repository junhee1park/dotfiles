#!/bin/sh
# Print a Claude Code or Codex transcript's conversation text, leaving out
# tool calls, tool output, and injected context.
case "$1" in
*.zst)
  zstdcat "$1" | jq -r '
    select(.type == "response_item" and .payload.type == "message"
           and (.payload.role == "user" or .payload.role == "assistant"))
    | .payload as $p | $p.content[]
    | select(.type == "input_text" or .type == "output_text") | .text
    | select((startswith("<") or startswith("# AGENTS.md")) | not)
    | if $p.role == "user" then "USER: " + . else "AGENT: " + .[0:600] end'
  ;;
*)
  jq -r '
    if .type == "user" and (.message.content | type) == "string"
       and (.message.content | startswith("<") | not) and (.isMeta | not)
    then "USER: " + .message.content
    elif .type == "assistant"
    then .message.content[]? | select(.type == "text") | "AGENT: " + .text[0:600]
    else empty end' "$1"
  ;;
esac
