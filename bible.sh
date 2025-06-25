#!/bin/bash

# bible.sh - Fetch Bible verses or chapters using the Bolls API
# Usage: bible -t [translation] "Book Chapter" or "Book Chapter:Verse"

# Default translation
translation="WEB"

# Helper functions

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(" ".join(sys.argv[1:])))' "$@"
}

get_book_id() {
  local bookname="$1"
  local translation="$2"
  local cache="$HOME/.cache/bible-cli/books-$translation.json"

  mkdir -p "$(dirname "$cache")"

  # Download and cache if not exists
  if [[ ! -f "$cache" ]]; then
    curl -s --max-time 5 "https://bolls.life/get-books/$translation/" -o "$cache"
  fi

jq --arg name "$(echo "$bookname" | tr '[:upper:]' '[:lower:]')" '
  .[] | select((.name | ascii_downcase) == $name) | .bookid
' "$cache"
}

parse_reference() {
  local ref="$1"

  # Case 0: Book StartChapter:StartVerse-EndChapter:EndVerse (allow hyphen, en dash, em dash)
  if [[ "$ref" =~ ^([^0-9]+)\ ([0-9]+):([0-9]+)[-–—]([0-9]+):([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    START_CHAPTER="${BASH_REMATCH[2]}"
    START_VERSE="${BASH_REMATCH[3]}"
    END_CHAPTER="${BASH_REMATCH[4]}"
    END_VERSE="${BASH_REMATCH[5]}"
    CROSS_CHAPTER_RANGE=1
    return
  fi

  # Case 1: Book Chapter:Start-End (allow hyphen, en dash, em dash)
  if [[ "$ref" =~ ^([^0-9]+)\ ([0-9]+):([0-9]+)[-–—]([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    CHAPTER="${BASH_REMATCH[2]}"
    VERSE=""
    VERSE_RANGE_START="${BASH_REMATCH[3]}"
    VERSE_RANGE_END="${BASH_REMATCH[4]}"
    VERSE_RANGE=($(seq "$VERSE_RANGE_START" "$VERSE_RANGE_END"))

  # Case 2: Book Chapter:Verse
  elif [[ "$ref" =~ ^([^0-9]+)\ ([0-9]+):([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    CHAPTER="${BASH_REMATCH[2]}"
    VERSE="${BASH_REMATCH[3]}"
    VERSE_RANGE=()

  # Case 3: Book Chapter
  elif [[ "$ref" =~ ^([^0-9]+)\ ([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    CHAPTER="${BASH_REMATCH[2]}"
    VERSE=""
    VERSE_RANGE=()

  else
    echo "❌ Invalid reference format: '$ref'" >&2
    exit 1
  fi
}

fetch_from_bolls() {
  local bookid="$1"
  local chapter="$2"
  local verse="$3"
  local translation="$4"

  # Case 1: Single verse
  if [[ -n "$verse" ]]; then
    local url="https://bolls.life/get-verse/$translation/$bookid/$chapter/$verse/"
    local json
    json=$(curl -s --max-time 5 "$url")

    if echo "$json" | grep -q 'text'; then
      echo "$json" | jq -r '"\(.verse). \(.text)"' | sed 's/<[^>]*>//g'
    else
      echo "❌ Could not retrieve verse." >&2
      return 1
    fi

  # Case 2: Range of verses
  elif [[ ${#VERSE_RANGE[@]} -gt 0 ]]; then
    local verses_json
verses_json=$(printf '%s\n' "${VERSE_RANGE[@]}" | jq -R 'tonumber' | jq -s .)

    local body
    body=$(jq -n \
      --arg translation "$translation" \
      --argjson book "$bookid" \
      --argjson chapter "$chapter" \
      --argjson verses "$verses_json" \
      '[{
        translation: $translation,
        book: $book,
        chapter: $chapter,
        verses: $verses
      }]'
    )

    local json
    json=$(curl -s --max-time 5 -X POST \
      -H "Content-Type: application/json" \
      -d "$body" https://bolls.life/get-verses/)

    if echo "$json" | jq empty 2>/dev/null; then
      echo "$json" | jq -r '.[0][] | "\(.verse). \(.text)"' | sed 's/<[^>]*>//g'
    else
      echo "❌ Could not retrieve multiple verses." >&2
      return 1
    fi

  # Case 3: Whole chapter
  else
    local url="https://bolls.life/get-text/$translation/$bookid/$chapter/"
    local json
    json=$(curl -s --max-time 5 "$url")

    if echo "$json" | grep -q 'text'; then
      echo "$json" | jq -r '.[] | "\(.verse). \(.text)"' | sed 's/<[^>]*>//g'
    else
      echo "❌ Could not retrieve chapter." >&2
      return 1
    fi
  fi
}

# Main CLI handler
bible() {
  local ref=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--translation)
        translation="$2"
        shift 2
        ;;
      --book-id)
        echo "$(get_book_id "$2" "$3")"
        exit 0
        ;;
      -h|--help)
        echo "Usage: bible [-t translation] \"Book Chapter[:Verse]\""
        exit 0
        ;;
      -*)
        echo "Unknown option: $1"
        exit 1
        ;;
      *)
        ref="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$ref" ]]; then
    echo "❌ Please provide a reference like "John 3:16" or "John 3"."
    exit 1
  fi

  parse_reference "$ref"

  if [[ "$CROSS_CHAPTER_RANGE" == "1" ]]; then
    bash "$(dirname "$0")/fetch_cross_chapter.sh" "$translation" "$BOOK" "$START_CHAPTER" "$START_VERSE" "$END_CHAPTER" "$END_VERSE"
    exit $?
  fi

  bookid=$(get_book_id "$BOOK" "$translation")

  if [[ -z "$bookid" ]]; then
    echo "❌ Could not find book: $BOOK in $translation."
    exit 1
  fi

  fetch_from_bolls "$bookid" "$CHAPTER" "$VERSE" "$translation"
}

# Entry point
bible "$@"
