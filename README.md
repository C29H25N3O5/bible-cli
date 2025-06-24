# 📖 bible-cli (WIP)

`bible-cli` is a simple command-line tool to fetch and display Bible passages directly in your terminal. It uses the Bible Gateway’s API to retrieve scripture in plain text with support for multiple translations.

> ⚠️ This project is a work in progress. It's already functional but may be refined further for features, performance, or packaging.

---

## ✨ Features

- 🔍 Fetch Bible passages by reference (e.g., `John 3:16`)
- 🗣 Choose between translations (e.g., `--translation kjv`)
- 🔢 Toggle verse numbers (`--verse`)
- 🧾 Append reference and translation info (`--info`)
- 📋 Copy to clipboard (`--copy`)
- 📜 Output formatting options (multi-line or single paragraph)
- 🐞 Debug mode to inspect raw API response

---

## 🚀 Usage

```bash
bible [options] "Book Chapter:Verse"
```

### Example

```bash
bible -v -i -t web Romans 8:38–39
```

## 🛠 Options

`-v`, `--verse`: Show verse numbers
`-n`, `--no-break`: Output as a single paragraph
`-i`, `--info`: Show reference and translation info
`-t`, `--translation`: Choose Bible version (web, kjv, etc.)
`-c`, `--copy`: Copy output to clipboard
`-d`, `--debug`: Print debug info and raw API response
`-h`, `--help`: Show help message

## 📦 Installation (WIP)

This tool is currently under development. When finished, you’ll be able to:
- Install via brew
- Or just clone and run the script directly

## License

GNU General Public License v3.0

