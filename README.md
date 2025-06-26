<p align="center">
  <img src="images/logo.png" alt="Logo" width="150"/>
</p>

# 📖 bible-cli (WIP)

🚧🚧🚧 WIP, NOT READY FOR DOWNLOAD YET 🚧🚧🚧

`bible-cli` is a simple command-line tool to fetch and display Bible passages directly in your terminal. It uses the [Bolls API](https://bolls.life/api/#Random%20verse) to retrieve scripture in plain text with support for multiple translations.

> ⚠️ This project is a work in progress. It’s already partially functional but needed to be refined further for features, performance, and packaging.

## ✨ Features

- 🔍 Fetch Bible passages by reference (e.g., `John 3:16`)
- 🗣 Choose between translations (e.g., `--translation kjv`)
- 🔢 Toggle verse numbers (`--verse`)
- 🧾 Append reference and translation info (`--info`)
- 📋 Copy to clipboard (`--copy`)
- 📜 Output formatting options (multi-line or single paragraph)
- 🐞 Debug mode to inspect raw API response

## 🚀 Usage

```bash
bible [options] "Book Chapter:Verse"
```

### Example

```bash
bible -v -i -t web Romans 8:38-39
```

## 🛠 Options

- `-v`, `--verse`: Show verse numbers
- `-n`, `--no-break`: Output as a single paragraph
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
- [ ] Listing available translations (for a language)
- [ ] Support for abbreviated chapter names
- [ ] Formatting
- [ ] Random verse
- [ ] Definition for Hebrew and Greek words
- [ ] Verse searching
- [ ] Reference tagging (?)