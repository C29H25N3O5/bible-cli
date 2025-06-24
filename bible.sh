#!/bin/bash

# bible - Fetch and display Bible verses from bible-api.com
# Usage: bible [options] "Book Chapter:Verse"

bible() {
  local show_verses=false
  local no_break=false
  local show_info=false
  local copy=false
  local translation="web"
  local debug=false
  local args=()

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verse)        show_verses=true; shift ;;
      -n|--no-break)     no_break=true; shift ;;
      -i|--info)         show_info=true; shift ;;
      -t|--translation)  translation="$2"; shift 2 ;;
      -c|--copy)         copy=true; shift ;;
      -d|--debug)        debug=true; shift ;;
      -h|--help)
        echo "Usage: bible [options] \"Book Chapter:Verse\""
        echo "Options:"
        echo "  -v, --verse         Show verse numbers"
        echo "  -n, --no-break      Remove line breaks, output as single paragraph"
        echo "  -i, --info          Append reference and translation info"
        echo "  -t, --translation   Specify translation (e.g., web, kjv)"
        echo "  -c, --copy          Copy to clipboard"
        echo "  -d, --debug         Print raw response and debug info"
        echo "  -h, --help          Show this help message"
        exit 0
        ;;
      -*)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    echo "Usage: bible [options] \"Book Chapter:Verse\""
    echo "Options:"
    echo "  -v, --verse         Show verse numbers"
    echo "  -n, --no-break      Remove line breaks, output as single paragraph"
    echo "  -i, --info          Append reference and translation info"
    echo "  -t, --translation   Specify translation (e.g., web, kjv)"
    echo "  -c, --copy          Copy to clipboard"
    echo "  -d, --debug         Print raw response and debug info"
    echo "  -h, --help          Show this help message"
    exit 1
  fi

  # Build query
  local joined_passage="${args[*]}"
  local encoded
  encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$joined_passage" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "Error: Python3 is required to encode the passage." >&2
    exit 1
  fi
  local url="https://bible-api.com/${encoded}?translation=${translation}"

  # Download
  local raw
  raw=$(curl -s "$url")
  if [[ -z "$raw" ]]; then
    echo "Error: Failed to fetch data from API." >&2
    exit 1
  fi

  if [[ "$debug" == true ]]; then
    echo "[Debug] Fetching URL: $url" >&2
    echo "$raw" > /tmp/bible-api-response.json
    echo "[Debug] Response saved to /tmp/bible-api-response.json" >&2
  fi

  # Create a temporary file for the JSON data
  local temp_file
  temp_file=$(mktemp)
  echo "$raw" > "$temp_file"

  # Run Python script with the temp file path as an argument
  local output
  output=$(python3 - "$show_verses" "$no_break" "$show_info" "$temp_file" <<'PY' 2>/dev/null
import sys, json

show_verses = sys.argv[1].lower() == "true"
no_break = sys.argv[2].lower() == "true"
show_info = sys.argv[3].lower() == "true"
with open(sys.argv[4], 'r') as f:
    data = json.load(f, strict=False)

try:
    verses = data['verses']
    processed_texts = [verse['text'].replace('\n', ' ').strip() for verse in verses]

    if no_break:
        if show_verses:
            texts = [f"[{verse['verse']}] {text}" for verse, text in zip(verses, processed_texts)]
        else:
            texts = processed_texts
        main_text = ' '.join(texts)
    else:
        if show_verses:
            main_text = '\n'.join([f"{verse['verse']}. {text}" for verse, text in zip(verses, processed_texts)])
        else:
            main_text = '\n'.join(processed_texts)

    print(main_text)

    if show_info:
        info = f"{data['reference']}, {data['translation_name']}"
        print('\n' + info)
except Exception as e:
    print(f"Error: Failed to extract verse: {e}", file=sys.stderr)
    sys.exit(1)
PY
)

  local python_status=$?

  # Clean up the temporary file
  rm "$temp_file"

  # Check if Python script failed
  if [[ $python_status -ne 0 ]]; then
    echo "Error: Failed to process API response." >&2
    exit 1
  fi

  # Output result
  echo "$output"

  # Copy to clipboard if requested
  if [[ "$copy" == true ]]; then
    command -v pbcopy >/dev/null && { echo "$output" | pbcopy; echo "[Copied to clipboard 📋]"; }
  fi
}

# Execute the bible function with all arguments
bible "$@"

