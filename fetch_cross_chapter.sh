##!/bin/bash

translation="$1"
bookname="$2"
start_chapter="$3"
start_verse="$4"
end_chapter="$5"
end_verse="$6"

# Get book ID using helper in bible.sh
bookid=$(bash "$(dirname "$0")/bible.sh" --book-id "$bookname" "$translation")
if [[ -z "$bookid" ]]; then
  echo "❌ Could not find book: $bookname in $translation."
  exit 1
fi

# Construct range
payload="["

for ((c=start_chapter; c<=end_chapter; c++)); do
  # Determine verse range
  if (( c == start_chapter )); then
    verse_start=$start_verse
  else
    verse_start=1
  fi

  if (( c == end_chapter )); then
    verse_end=$end_verse
  else
    # Fetch max verse from book data
    chapter_info=$(curl -s --max-time 5 "https://bolls.life/get-text/$translation/$bookid/$c/")
    verse_end=$(echo "$chapter_info" | jq '.[].verse' | sort -n | tail -n 1)
  fi

  # Add to payload
  verses=$(seq "$verse_start" "$verse_end" | jq -R 'tonumber' | jq -s .)
  chunk=$(jq -n \
    --arg translation "$translation" \
    --argjson book "$bookid" \
    --argjson chapter "$c" \
    --argjson verses "$verses" \
    '{ translation: $translation, book: $book, chapter: $chapter, verses: $verses }')
  payload+="$chunk,"
done

# Remove trailing comma and wrap
payload="${payload%,}]"

# POST request
response=$(curl -s --max-time 5 -X POST -H "Content-Type: application/json" \
  -d "$payload" https://bolls.life/get-verses/)

if echo "$response" | jq empty 2>/dev/null; then
  echo "$response" | jq -r '.[][] | "\(.verse). \(.text)"' | sed 's/<[^>]*>//g'
else
  echo "❌ Could not retrieve cross-chapter verses." >&2
  exit 1
fi
