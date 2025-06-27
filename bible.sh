#!/bin/bash

# bible.sh - Fetch Bible verses or chapters using the Bolls API
# Usage: bible -t [translation] "Book Chapter" or "Book Chapter:Verse"


# Default translation
translation="WEB"
include_strongs=false

# Verse formatting options
verse_style="default"  # default, chapter, brackets, none
one_line=false
random_verse=false

# Jewish/Masoretic reference mode flag
# When true, remaps references to Jewish chapter/verse numbering for known books.
# This affects output references and fetched verses.
use_masoretic=false
# -------------------------------------------
# Remap Christian reference to Masoretic Jewish numbering where known differences occur.
# This function adjusts BOOK, CHAPTER, VERSE, VERSE_RANGE, etc. as needed.
# Examples:
# - Genesis 31/32: Jewish Genesis 32:1 = Christian Genesis 31:55
# - Psalms: Psalm titles are counted as verse 1 in Jewish, so add +1 to verse numbers.
# - Joel: Jewish Joel 3:1 = Christian Joel 2:28, chapters shifted by +1 after ch 2
# - Malachi: Jewish Malachi 3:23 = Christian Malachi 4:5 (Malachi has 4 chapters Christian, 3 Jewish)
# Only known differences are handled.
remap_reference_to_masoretic() {
  # Only remap certain books
  case "$BOOK" in
    Genesis)
      # Genesis 32:1 in Jewish = 31:55 in Christian; Christian 32:1 = Jewish 32:2
      # If reference is Genesis 32, shift verses by -1 for verse 1, else unchanged
      if [[ "$CHAPTER" == "32" ]]; then
        if [[ -n "$VERSE" && "$VERSE" == "1" ]]; then
          CHAPTER="31"
          VERSE="55"
        elif [[ -n "${VERSE_RANGE[*]}" ]]; then
          # If verse range includes 1, shift 1 to 31:55, rest unchanged
          for i in "${!VERSE_RANGE[@]}"; do
            if [[ "${VERSE_RANGE[$i]}" == "1" ]]; then
              VERSE_RANGE[$i]="55"
              CHAPTER="31"
            fi
          done
        fi
      fi
      ;;
    Psalms)
      # In Jewish numbering, Psalm titles are verse 1, so all verse numbers shift +1
      # e.g., Christian 23:1 = Jewish 23:2
      if [[ -n "$VERSE" ]]; then
        ((VERSE=VERSE+1))
      elif [[ -n "${VERSE_RANGE[*]}" ]]; then
        for i in "${!VERSE_RANGE[@]}"; do
          ((VERSE_RANGE[$i]=VERSE_RANGE[$i]+1))
        done
      fi
      ;;
    Joel)
      # In Jewish, Joel is 4 chapters; Christian is 3. Chapter 3 in Christian = 4 in Jewish.
      # Christian 2:28-32 = Jewish 3:1-5
      if [[ -n "$CHAPTER" ]]; then
        if (( CHAPTER == 3 )); then
          CHAPTER=4
        elif (( CHAPTER == 2 )) && [[ -n "$VERSE" ]] && (( VERSE >= 28 )); then
          CHAPTER=3
          ((VERSE=VERSE-27))
        elif (( CHAPTER == 2 )) && [[ -n "${VERSE_RANGE[*]}" ]] && (( VERSE_RANGE[0] >= 28 )); then
          CHAPTER=3
          for i in "${!VERSE_RANGE[@]}"; do
            ((VERSE_RANGE[$i]=VERSE_RANGE[$i]-27))
          done
        fi
      fi
      ;;
    Malachi)
      # Christian Malachi has 4 chapters, Jewish has 3; Christian 4:1 = Jewish 3:19
      if [[ -n "$CHAPTER" ]]; then
        if (( CHAPTER == 4 )); then
          CHAPTER=3
          if [[ -n "$VERSE" ]]; then
            ((VERSE=VERSE+18))
          elif [[ -n "${VERSE_RANGE[*]}" ]]; then
            for i in "${!VERSE_RANGE[@]}"; do
              ((VERSE_RANGE[$i]=VERSE_RANGE[$i]+18))
            done
          fi
        fi
      fi
      ;;
    *)
      # No remapping for other books
      ;;
  esac
}

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

  # Case 3A: Book StartChapter-EndChapter (allow hyphen, en dash, em dash)
  if [[ "$ref" =~ ^(.+)\ ([0-9]+)[-–—]([0-9]+)$ ]]; then
    BOOK="${BASH_REMATCH[1]}"
    START_CHAPTER="${BASH_REMATCH[2]}"
    END_CHAPTER="${BASH_REMATCH[3]}"
    CROSS_CHAPTER_RANGE=1
    START_VERSE=1
    END_VERSE=999
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

  # Determine how to handle Strong's tags
  if [[ "$include_strongs" == true ]]; then
    strong_pattern='s|<S>([0-9]+)</S>|(\1)|g'
  else
    strong_pattern='s|<S>[0-9]+</S>||g'
  fi

  # Case 1: Single verse
  if [[ -n "$verse" ]]; then
    local url="https://bolls.life/get-verse/$translation/$bookid/$chapter/$verse/"
    local json
    json=$(curl -s --max-time 5 "$url")

    if echo "$json" | grep -q 'text'; then
      # Build jq filter per verse_style
      case "$verse_style" in
        none)
          jq_filter='.text'
          ;;
        brackets)
          jq_filter='"[" + (.verse|tostring) + "] " + .text'
          ;;
        chapter)
          jq_filter='"'$BOOK' '$chapter':" + (.verse|tostring) + " " + .text'
          ;;
        *)
          jq_filter='(.verse|tostring) + ". " + .text'
          ;;
      esac

      # Generate and clean output
      output=$(echo "$json" | jq -r "$jq_filter" \
        | sed -E "$strong_pattern" | sed -E 's;<sup>[^<]*</sup>;;g; s;<[^>]+>;;g; s/ +([,.;:?!])/\1/g')

      # Join into one line if requested
      if [[ "$one_line" == true ]]; then
        output=$(echo "$output" | tr '\n' ' ')
      fi

      echo "$output"
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
      # Build jq filter per verse_style
      case "$verse_style" in
        none)
          jq_filter='.text'
          ;;
        brackets)
          jq_filter='"[" + (.verse|tostring) + "] " + .text'
          ;;
        chapter)
          jq_filter='"'$chapter':" + (.verse|tostring) + " " + .text'
          ;;
        *)
          jq_filter='(.verse|tostring) + ". " + .text'
          ;;
      esac

      # Generate and clean output
      output=$(echo "$json" | jq -r '.[][] | '"$jq_filter" \
        | sed -E "$strong_pattern" | sed -E 's;<sup>[^<]*</sup>;;g; s;<[^>]+>;;g; s/ +([,.;:?!])/\1/g')

      # Join into one line if requested
      if [[ "$one_line" == true ]]; then
        output=$(echo "$output" | tr '\n' ' ')
      fi

      echo "$output"
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
      # Build jq filter per verse_style
      case "$verse_style" in
        none)
          jq_filter='.[] | .text'
          ;;
        brackets)
          jq_filter='.[] | "[" + (.verse|tostring) + "] " + .text'
          ;;
        chapter)
          jq_filter='.[] | "'$chapter':" + (.verse|tostring) + " " + .text'
          ;;
        *)
          jq_filter='.[] | (.verse|tostring) + ". " + .text'
          ;;
      esac

      # Generate and clean output
      output=$(echo "$json" | jq -r "$jq_filter" \
        | sed -E "$strong_pattern" | sed -E 's;<sup>[^<]*</sup>;;g; s;<[^>]+>;;g; s/ +([,.;:?!])/\1/g')

      # Join into one line if requested
      if [[ "$one_line" == true ]]; then
        output=$(echo "$output" | tr '\n' ' ')
      fi

      echo "$output"
    else
      echo "❌ Could not retrieve chapter." >&2
      return 1
    fi
  fi
}

handle_multi_reference() {
  local allrefs="$1"
  local translation="$2"
  local IFS_old="$IFS"
  IFS=',;'
  last_book=""
  last_chapter=""
  for segment in $allrefs; do
    segment="$(echo "$segment" | xargs)"  # trim whitespace
    # Inherit book/chapter context when omitted
    if [[ -n "$last_book" ]]; then
      if [[ "$segment" =~ ^[0-9]+([-–—][0-9]+)?$ ]]; then
        # verse or verse-range only
        segment="$last_book $last_chapter:$segment"
      elif [[ "$segment" =~ ^[0-9]+:[0-9]+([-–—][0-9]+)?$ ]]; then
        # chapter:verse or range without book
        segment="$last_book $segment"
      fi
    fi
    # Reset CROSS_CHAPTER_RANGE flag
    CROSS_CHAPTER_RANGE=0
    parse_reference "$segment"
    # Update context for next segments
    last_book="$BOOK"
    last_chapter="${CHAPTER:-$START_CHAPTER}"
    if [[ "$CROSS_CHAPTER_RANGE" == "1" ]]; then
      bash "$(dirname "$0")/fetch_cross_chapter.sh" "$translation" "$BOOK" "$START_CHAPTER" "$START_VERSE" "$END_CHAPTER" "$END_VERSE"
    else
      local bookid
      bookid=$(get_book_id "$BOOK" "$translation")
      fetch_from_bolls "$bookid" "$CHAPTER" "$VERSE" "$translation"
    fi
  done
  IFS="$IFS_old"
  exit 0
}


# Main CLI handler
bible() {
  local ref=""
  local list_language=""
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
      -s|--strong)
        include_strongs=true
        shift
        ;;
      -j|--jewish)
        use_masoretic=true
        shift
        ;;
      -l|--list)
        list_language="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: bible [-t translation] [-j|--jewish] [-l language] \"Book Chapter[:Verse]\""
        echo "  -t, --translation   Specify translation short code (default: WEB)"
        echo "  -j, --jewish       Use Jewish/Masoretic numbering for known books"
        echo "  -l, --list LANG    List available translations for a language (case-insensitive substring match)"
        echo "  -s, --strong       Include Strong's numbers (if available)"
        echo "  -h, --help         Show this help"
        echo "  -c, --chapter      Show verse numbers as chapter:verse"
        echo "  -b, --brackets     Show verse numbers in square brackets"
        echo "  -n, --no-verse     Do not show verse numbers"
        echo "  -o, --one-line     Output all verses on one line (no line breaks)"
        echo "  -r, --random       Fetch a random verse (requires -t for translation)"
        exit 0
        ;;
      -c|--chapter)
        verse_style="chapter"
        shift
        ;;
      -b|--brackets)
        verse_style="brackets"
        shift
        ;;
      -n|--no-verse)
        verse_style="none"
        shift
        ;;
      -o|--one-line)
        one_line=true
        shift
        ;;
      -r|--random)
        random_verse=true
        shift
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

  # Handle listing of translations for a language
  if [[ -n "$list_language" ]]; then
    local lang_json
    lang_json=$(curl -s --max-time 8 "https://bolls.life/static/bolls/app/views/languages.json")
    if [[ -z "$lang_json" ]]; then
      echo "❌ Could not fetch language list." >&2
      exit 1
    fi
    # Find matching language (case-insensitive substring match)
    local lang_entry
    lang_entry=$(echo "$lang_json" | jq --arg q "$list_language" '
      .[] | select(.language | ascii_downcase | test($q|ascii_downcase))
    ')
    if [[ -z "$lang_entry" ]]; then
      echo "❌ No language found matching: $list_language" >&2
      exit 1
    fi
    # Count number of translations
    local count
    count=$(echo "$lang_entry" | jq '.translations | length')
    local lang_name
    lang_name=$(echo "$lang_entry" | jq -r '.language')
    echo "Found $count translation(s) for language: $lang_name"
    echo
    echo "$lang_entry" | jq -r '.translations[] | "\(.short_name)\t\(.full_name)"'
    exit 0
  fi

  # Handle random verse flag
  if [[ "$random_verse" == true ]]; then
    if [[ -z "$translation" ]]; then
      echo "❌ Please specify a translation with -t for random verse."
      exit 1
    fi

    json=$(curl -s --max-time 5 "https://bolls.life/get-random-verse/$translation/")
    if echo "$json" | grep -q 'text'; then
      BOOK_ID=$(echo "$json" | jq -r '.book')
      CHAPTER=$(echo "$json" | jq -r '.chapter')
      VERSE=$(echo "$json" | jq -r '.verse')

      # Lookup book name from book id
      BOOK=$(curl -s --max-time 5 "https://bolls.life/get-books/$translation/" | jq -r --argjson bid "$BOOK_ID" '.[] | select(.bookid == $bid) | .name')

      VERSE_RANGE=()
      verse_text=$(echo "$json" | jq -r '.text')

      case "$verse_style" in
        none)
          formatted="$verse_text"
          ;;
        brackets)
          formatted="[$VERSE] $verse_text"
          ;;
        chapter)
          formatted="$BOOK $CHAPTER:$VERSE $verse_text"
          ;;
        *)
          formatted="$BOOK $CHAPTER:$VERSE $verse_text"
          ;;
      esac

      if [[ "$include_strongs" == false ]]; then
        formatted=$(echo "$formatted" | sed -E 's|<S>[0-9]\+</S>||g')
      else
        formatted=$(echo "$formatted" | sed -E 's|<S>[0-9]\+</S>|(\0)|g; s|<S>\([0-9]\+\)</S>|(\1)|g')
      fi

      # Clean HTML tags
      formatted=$(echo "$formatted" | sed -E 's:<sup>[^<]*</sup>::g; s:<[^>]+>::g; s/ +([,.;:?!])/\1/g')

      # Collapse into one line if necessary
      if [[ "$one_line" == true ]]; then
        formatted=$(echo "$formatted" | tr '\n' ' ')
      fi

      echo "$formatted"
      exit 0
    else
      echo "❌ Could not fetch random verse." >&2
      exit 1
    fi
  fi

  if [[ -z "$ref" ]]; then
    echo "❌ Please provide a reference like \"John 3:16\" or \"John 3\"."
    exit 1
  fi

  # Handle comma- or semicolon-separated references
  if [[ "$ref" =~ [,\;] ]]; then
    handle_multi_reference "$ref" "$translation"
  fi

  parse_reference "$ref"
  if [[ "$use_masoretic" == true ]]; then
    remap_reference_to_masoretic
  fi

  if [[ "$CROSS_CHAPTER_RANGE" == "1" ]]; then
    bash "$(dirname "$0")/fetch_cross_chapter.sh" "$translation" "$BOOK" "$START_CHAPTER" "$START_VERSE" "$END_CHAPTER" "$END_VERSE"
    exit $?
  fi

  bookid=$(get_book_id "$BOOK" "$translation")

  if [[ -z "$bookid" ]]; then
    echo "❌ Could not find book: $BOOK in $translation."
    exit 1
  fi

  # Print reference, noting Masoretic/Jewish if in that mode
  if [[ "$use_masoretic" == true ]]; then
    echo "Jewish/Masoretic numbering: $BOOK ${CHAPTER}${VERSE:+:$VERSE}"
  fi

  fetch_from_bolls "$bookid" "$CHAPTER" "$VERSE" "$translation"
}

# Entry point
bible "$@"
