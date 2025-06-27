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

- `-v`, `--verse`: Show verse numbers
- `-c`, `--chapter`: Show chapter:verse instead of just verse numbers
- `-b`, `--brackets`: Show verse numbers in square brackets
- `-n`, `--no-verse`: Do not show verse numbers
- `-o`, `--one-line`: Display multiple verses in one line
- `-j`, `--jewish`: Use Jewish verse/chapter numbering
- `-s`, `--strong`: Show Strong's numbers
- `-r`, `--random`: Get a random verse
- `-l`, `--list`: List available translations for a language
- `-i`, `--info`: Show reference and translation info
- `-t`, `--translation`: Choose Bible version (web, kjv, etc.)
- `-c`, `--copy`: Copy output to clipboard
- `-d`, `--debug`: Print debug info and raw API response
- `-h`, `--help`: Show help message

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