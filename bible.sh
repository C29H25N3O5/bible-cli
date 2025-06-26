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

  # Normalize various Unicode space characters to regular spaces, and squeeze multiple spaces
  ref=$(echo "$ref" | perl -CS -pe 's/[\x{00A0}\x{2009}\x{200A}\x{202F}\x{205F}\x{3000}]/ /g; s/ +/ /g')

  # Normalize separators like period to colon
  ref=$(echo "$ref" | sed -E 's/([0-9]+)[.．]([0-9]+)/\1:\2/g')

  # Normalize common book abbreviations (using Perl for reliable word boundary matching)
  ref=$(echo "$ref" | perl -pe '
    s/\b(Gen|Ge|Gn|Bereshit)\b/Genesis/ig;
    s/\b(Exod|Exo|Ex|Shemot)\b/Exodus/ig;
    s/\b(Lev|Le|Lv|Vayikra)\b/Leviticus/ig;
    s/\b(Num|Nu|Nm|Nb|Bamidbar)\b/Numbers/ig;
    s/\b(Deut|De|Dt|Devarim)\b/Deuteronomy/ig;
    s/\b(Josh|Jos|Jsh|Yehoshua)\b/Joshua/ig;
    s/\b(Judg|Jdg|Jg|Jdgs|Shoftim)\b/Judges/ig;
    s/\b(Rth|Ru|Rut)\b/Ruth/ig;
    s/\b(1 Sam|1 Sa|1S|1 S|I Sa|1 Sm|1Sa|1st Sam|1st Samuel|I Samuel|First Sam|First Samuel|Shmuel Alef)\b/1 Samuel/ig;
    s/\b(2 Sam|2 Sa|2S|2 S|II Sa|2 Sm|2Sa|2nd Sam|2nd Samuel|II Samuel|Second Sam|Second Samuel|Shmuel Bet)\b/2 Samuel/ig;
    s/\b(1 Kgs|1 Ki|1K|1 K|I Kgs|1Kgs|I Ki|1Ki|1Kin|1st Kgs|1st Kings|I Kings|First Kgs|First Kings|Melakhim Alef)\b/1 Kings/ig;
    s/\b(2 Kgs|2 Ki|2K|2 K|II Kgs|2Kgs|II Ki|2Ki|2Kin|2nd Kgs|2nd Kings|II Kings|Second Kgs|Second Kings|Melachim Bet)\b/2 Kings/ig;
    s/\b(1 Chron|1 Ch|1C|I Ch|1Ch|1 Chr|I Chr|1Chr|I Chron|1Chron|1st Chron|1st Chronicles|I Chronicles|First Chron|First Chronicles|Divrei HaYamim Alef)\b/1 Chronicles/ig;
    s/\b(2 Chron|2 Ch|2C|II Ch|2Ch|II Chr|2Chr|II Chron|2Chron|2nd Chron|2nd Chronicles|II Chronicles|Second Chron|Second Chronicles|Divrei HaYamim Bet)\b/2 Chronicles/ig;
    s/\b(Ezr|Ez)\b/Ezra/ig;
    s/\b(Neh|Ne|Nechemyah)\b/Nehemiah/ig;
    s/\b(Esth|Es|Ester)\b/Esther/ig;
    s/\b(Jb|Iyov)\b/Job/ig;
    s/\b(Psalm|Pslm|Ps|Psa|Psm|Pss|Tehilim)\b/Psalms/ig;
    s/\b(Prov|Pro|Pr|Prv|Mishlei)\b/Proverbs/ig;
    s/\b(Eccles|Eccle|Ecc|Ec|Qoh|Kohelet)\b/Ecclesiastes/ig;
    s/\b(Song of Songs|Song|So|SOS|Canticle of Canticles|Canticles|Cant|Shir HaShirim)\b/Song of Solomon/ig;
    s/\b(Isa|Is|Yeshayahu)\b/Isaiah/ig;
    s/\b(Jer|Je|Jr|Yirmeyahu)\b/Jeremiah/ig;
    s/\b(Lam|La|Eikhah)\b/Lamentations/ig;
    s/\b(Ezek|Eze|Ezk|Yechezkel)\b/Ezekiel/ig;
    s/\b(Dan|Da|Dn|Daniyel)\b/Daniel/ig;
    s/\b(Hos|Ho|Hoshea)\b/Hosea/ig;
    s/\b(Joe|Jl|Yoel)\b/Joel/ig;
    s/\b(Am)\b/Amos/ig;
    s/\b(Obad|Ob|Ovadiah)\b/Obadiah/ig;
    s/\b(Jnh|Jon|Yonah)\b/Jonah/ig;
    s/\b(Micah|Mic|Mc|Mikhah)\b/Micah/ig;
    s/\b(Nah|Na|Nachum)\b/Nahum/ig;
    s/\b(Hab|Hb)\b/Habakkuk/ig;
    s/\b(Zeph|Zep|Zp|Tzefanyah)\b/Zephaniah/ig;
    s/\b(Haggai|Hag|Hg|Chaggai)\b/Haggai/ig;
    s/\b(Zech|Zec|Zc|Zekharyah)\b/Zechariah/ig;
    s/\b(Mal|Ml|Malakhi)\b/Malachi/ig;
    s/\b(Matt|Mt)\b/Matthew/ig;
    s/\b(Mrk|Mar|Mk|Mr)\b/Mark/ig;
    s/\b(Luk|Lk)\b/Luke/ig;
    s/\b(John|Joh|Jhn|Jn)\b/John/ig;
    s/\b(Act|Ac)\b/Acts/ig;
    s/\b(Rom|Ro|Rm)\b/Romans/ig;
    s/\b(Gal|Ga)\b/Galatians/ig;
    s/\b(Ephes|Eph)\b/Ephesians/ig;
    s/\b(Phil|Php|Pp)\b/Philippians/ig;
    s/\b(Col|Co)\b/Colossians/ig;
    s/\b(Heb)\b/Hebrews/ig;
    s/\b(James|Jas|Jm)\b/James/ig;
    s/\b(Jude|Jud|Jd)\b/Jude/ig;
    s/\b(Rev|Re|The Revelation)\b/Revelation/ig;
    s/\b(Tobit|Tob|Tb)\b/Tobit/ig;
    s/\b(Jdth|Jdt|Jth)\b/Judith/ig;
    s/\b(Add Esth|Add Es|Rest of Esther|The Rest of Esther|AEs|AddEsth)\b/Additions to Esther/ig;
    s/\b(Wisd of Sol|Wis|Ws|Wisdom)\b/Wisdom of Solomon/ig;
    s/\b(Sirach|Sir|Ecclesiasticus|Ecclus)\b/Sirach/ig;
    s/\b(Baruch|Bar)\b/Baruch/ig;
    s/\b(Let Jer|Ltr Jer|LJe)\b/Letter of Jeremiah/ig;
    s/\b(Song of Three|Song Thr|The Song of Three Youths|Pr Az|Prayer of Azariah|Azariah|The Song of the Three Holy Children|The Song of Three Jews|Song of the Three Holy Children|Song of Thr|Song of Three Children|Song of Three Jews)\b/Song of Three Youths/ig;
    s/\b(Susanna|Sus)\b/Susanna/ig;
    s/\b(Bel)\b/Bel and the Dragon/ig;
    s/\b(1 Macc|1 Mac|1M|I Ma|1Ma|I Mac|1Mac|I Macc|1Macc|I Maccabees|1Maccabees|1st Maccabees|First Maccabees)\b/1 Maccabees/ig;
    s/\b(2 Macc|2 Mac|2M|II Ma|2Ma|II Mac|2Mac|II Macc|2Macc|II Maccabees|2Maccabees|2nd Maccabees|Second Maccabees)\b/2 Maccabees/ig;
    s/\b(1 Esdr|1 Esd|I Es|1Es|I Esd|1Esd|I Esdr|1Esdr|I Esdras|1Esdras|1st Esdras|First Esdras)\b/1 Esdras/ig;
    s/\b(Pr of Man|Pr Man|PMa|Prayer of Manasses)\b/Prayer of Manasseh/ig;
    s/\b(Add Psalm|Add Ps)\b/Additional Psalm/ig;
    s/\b(3 Macc|3 Mac|III Ma|3Ma|III Mac|3Mac|III Macc|3Macc|III Maccabees|3rd Maccabees|Third Maccabees)\b/3 Maccabees/ig;
    s/\b(2 Esdr|2 Esd|II Es|2Es|II Esd|2Esd|II Esdr|2Esdr|II Esdras|2Esdras|2nd Esdras|Second Esdras)\b/2 Esdras/ig;
    s/\b(4 Macc|4 Mac|IV Ma|4Ma|IV Mac|4Mac|IV Macc|4Macc|IV Maccabees|IIII Macc|4Maccabees|4th Maccabees|Fourth Maccabees)\b/4 Maccabees/ig;
    s/\b(Ode)\b/Ode/ig;
    s/\b(Ps Solomon|Ps Sol|Psalms Solomon|PsSol)\b/Psalms of Solomon/ig;
    s/\b(Laodiceans|Laod|Ep Laod|Epist Laodiceans|Epistle Laodiceans|Epistle to Laodiceans)\b/Epistle to the Laodiceans/ig;
  ')
  BOOK=$(echo "$ref" | cut -d ' ' -f1)

  # Normalize periods used as separators again before regex parsing
  ref=$(echo "$ref" | sed -E 's/([0-9]+)[.．]([0-9]+)/\1:\2/g')

  # Case 0: Book StartChapter:StartVerse-EndChapter:EndVerse (allow hyphen, en dash, em dash)
  if [[ "$ref" =~ ^(.+)\ ([0-9]+):([0-9]+)[-–—]([0-9]+):([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    START_CHAPTER="${BASH_REMATCH[2]}"
    START_VERSE="${BASH_REMATCH[3]}"
    END_CHAPTER="${BASH_REMATCH[4]}"
    END_VERSE="${BASH_REMATCH[5]}"
    CROSS_CHAPTER_RANGE=1
    return
  fi

  # Case 1: Book Chapter:Start-End (allow hyphen, en dash, em dash)
  if [[ "$ref" =~ ^(.+)\ ([0-9]+):([0-9]+)[-–—]([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    CHAPTER="${BASH_REMATCH[2]}"
    VERSE=""
    VERSE_RANGE_START="${BASH_REMATCH[3]}"
    VERSE_RANGE_END="${BASH_REMATCH[4]}"
    VERSE_RANGE=($(seq "$VERSE_RANGE_START" "$VERSE_RANGE_END"))

  # Case 2: Book Chapter:Verse
  elif [[ "$ref" =~ ^(.+)\ ([0-9]+):([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    CHAPTER="${BASH_REMATCH[2]}"
    VERSE="${BASH_REMATCH[3]}"
    VERSE_RANGE=()

  # Case 3: Book Chapter
  elif [[ "$ref" =~ ^(.+)\ ([0-9]+)$ ]]; then
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
