<p align="center">
  <img src="images/logo.png" alt="Logo" width="150"/>
</p>

# 📖 bible-cli (WIP)

🚧🚧🚧 **WIP, NOT READY FOR DOWNLOAD YET** 🚧🚧🚧

`bible-cli` is a simple command-line tool to fetch and display Bible passages directly in your terminal. It uses the [Bolls API](https://bolls.life/api/#Random%20verse) to retrieve scripture in plain text with support for multiple translations.

> ⚠️ This project is a work in progress. It’s already partially functional but needed to be refined further for features, performance, and packaging.

## ✨ Features

- 🔍 Fetch Bible passages by reference (e.g., `John 3:16`)
- 🗣 Choose between translations (e.g., `--translation kjv`)
- 🔢 Show verse numbers with multiple formatting options
- 🧾 Append reference and translation info
- 📋 Copy to clipboard (`--copy`)
- 📜 Output formatting options (multi-line, single paragraph, one-line)
- 🐞 Debug mode to inspect raw API response
- 💪 Show Strong's numbers
- 🎲 Get a random verse
- 📜 List available translations for a language
- ✡️ Use Jewish verse/chapter numbering

## 🚀 Usage

```bash
bible [options] "Book Chapter:Verse"
```

### Example

```bash
bible -v -i -t web -s -r -l -c -b -n -o -j Romans 8:38-39
```

## 🛠 Options

- `-t`, `--translation`: Specify translation short code (default: WEB)"
- `-j`, `--jewish`: Use Jewish/Masoretic numbering for known books"
- `-l`, `--list` LANG: List available translations for a language (case-insensitive substring match)"
- `-s`, `--strong`: Include Strong's numbers (if available)"
- `-h`, `--help`: Show this help"
- `--ch`, `--chapter`: Show verse numbers as chapter:verse"
- `-b`, `--brackets`: Show verse numbers in square brackets"
- `-n`, `--no`-verse: Do not show verse numbers"
- `-o`, `--one`-line: Output all verses on one line (no line breaks)"
- `-r`, `--random`: Fetch a random verse (requires -t for translation)"

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
  - [ ] Make it compatible with the `-s` tag
- [ ] Definition for Hebrew and Greek words
- [ ] Verse searching
- [ ] Reference tagging (?)