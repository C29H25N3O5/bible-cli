<p align="center">
  <img src="images/logo.png" alt="Logo" width="150"/>
</p>

# 📖 bible-cli (WIP)

🚧🚧🚧 **WIP, NOT READY FOR DOWNLOAD YET** 🚧🚧🚧

`bible-cli` is a simple command-line tool to fetch and display Bible passages directly in your terminal. It uses the [Bolls API](https://bolls.life/api/#Random%20verse) to retrieve scripture in plain text with support for multiple translations.

> ⚠️ This project is a work in progress. It’s already partially functional but needed to be refined further for features, performance, and packaging.

## ✨ Features

- 🔍 Fetch Bible passages by reference (supports complex formats and abbreviations)
- 🌍 Choose between translations (case-insensitive via `--translation` or `-t`)
- 🔠 Flexible verse number display (standard, brackets, none, chapter:verse)
- 🧾 Show Strong's numbers (with optional substitution formatting)
- ✂️ Replace the divine name (YHWH, Yahweh, etc.) with customizable output
- 🎲 Get a random verse (`--random`)
- 📜 List available translations by language (`--list`)
- ✡️ Use Jewish verse/chapter numbering (`--jewish`)
- 🧪 Debug mode to inspect API response
- 📋 Copy output to clipboard (`--copy`)

## 🚀 Usage

```bash
bible [options] "Book Chapter:Verse"
```

### Example

```bash
$ bible -t NIV -d "YHWH" --ch "Deut 6:4-5"

6:4 Hear, O Israel: YHWH our God, YHWH is one.
6:5 Love YHWH your God with all your heart and with all your soul and with all your strength.
```

## 🛠 Options

- `-t`, `--translation` STR: Specify translation short code (case-insensitive; default: WEB)
- `-j`, `--jewish`: Use Jewish/Masoretic numbering for known books
- `-l`, `--list` LANG: List available translations for a language (case-insensitive match)
- `-s`, `--strong`: Include Strong's numbers (if available)
- `-d`, `--divine-name` STR: Replace the divine name with STR (e.g., 'YHWH', 'Yahweh', or 'LORD')
- `-r`, `--random`: Fetch a random verse (requires `-t`)
- `-c`, `--copy`: Copy output to clipboard
- `--ch`, `--chapter`: Show verse numbers as Chapter:Verse
- `-b`, `--brackets`: Show verse numbers in square brackets
- `-n`, `--no-verse`: Omit verse numbers
- `-o`, `--one-line`: Output all verses in one line
- `-h`, `--help`: Show help information

## 📦 Installation (WIP)

This tool is currently under development. When finished, you’ll be able to:
- Install via Homebrew
- Or just clone and run the script directly

## License

GNU General Public License v3.0

## Todos
- [X] `KJV` uses non-Strong’s number version of KJV
- [X] Verses spanning multiple paragraphs
- [X] Listing available translations (for a language)
- [X] Support for abbreviated chapter names
- [X] Support for Jewish verse numbering
- [X] Formatting
  - [X] Chapter:Verse
  - [X] Verse numbers in square brackets
  - [X] No verse numbers
  - [X] One-line output for multiple verses
- [X] Random verse
  - [ ] Make random verse compatible with the `-s` tag
- [X] Divine name substitution
- [ ] Definition for Hebrew and Greek words
- [ ] Verse searching
- [ ] Reference tagging (?)