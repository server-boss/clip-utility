# Clip ✂︎

I got tired of copying text from one app to another, only for it to have butchered formatting, broken tables, mangled lists, or aggravating whitespace/line-breaks. Enter... `clip` ... my multi-tool that bundles a CLI with wide range of powerful clipboard tools, a live-preview TUI, and a MacOS-native popup for quick access to the tool outside of the terminal!

## The Problem

| You copied from... | You're pasting into... | What happens |
|---|---|---|
| Claude Code / terminal session | Gmail or Word | Tables break, formatting lost |
| Gmail or Word | GitHub or Typora | HTML tags everywhere |
| Excel | Apple Notes | Table becomes one long line |
| Any AI tool | Anywhere else | Smart quotes, weird dashes, broken wrapping |

## The Fix(es)

Use the interactive TUI with live preview — select transforms and see the result before applying:

`clip-tui`

![clip-tui](assets/tui.png)
![Result pasted into Markdown Editor](assets/rich-paste.png)

Or open a native MacOS pop-up from the terminal or with a simple Apple "Shortcut", that you can bind to a keyboard/mouse shortcut and add to your menu bar:

`clip-menu`

![Main menu](assets/menu-main.png) 
![Format options](assets/menu-format.png)
![Shortcut setup](assets/shortcut-setup.png)

Or use the CLI directly, to add arguments in order that they will be applied:

`clip`

```bash
clip --claude --unwrap --tohtml        # Terminal → Gmail/Word/Notes (with tables!)
clip --md --rtrim --strip-blank        # Rich text → clean Markdown
clip --tohtml                          # Markdown → formatted email
clip --claude --unwrap --toexcel       # Terminal → Excel spreadsheet
```

## Installation Guide for MacOS (Homebrew)

```bash
brew tap server-boss/clip-utility && brew install clip-utility
```
**pandoc** (optional) — required for `--md` and `--tohtml` transforms
`brew install pandoc`

**fzf** (optional) — required for `clip-tui`
`brew install fzf`

### Apple-Shortcut Setup

Create a new shortcut in Shortcuts.app with a "Run Shell Script" action. 
Set the script to the path of `clip-menu`, shell to `bash`, and input to "Clipboard". 
Assign a keyboard shortcut (e.g. `Option+Shift+C`) under the shortcut's details (i).

![Shortcut setup](assets/shortcut-setup.png)
![Shortcut privacy](assets/shortcut-privacy.png)

## Full Clip CLI Argument List

### Clipboard Source

| Flag | Description |
|------|-------------|
| `--claude` | Claude terminal output → clean Markdown |
| `--md` | Rich HTML clipboard → Markdown (requires pandoc) |
| `--boxtable` | Box-drawing table → Markdown table |
| `--unwrap` | Rejoin hard-wrapped paragraph lines |

### Formatting

| Flag | Description |
|------|-------------|
| `--trim` | Strip leading + trailing whitespace |
| `--rtrim` | Strip trailing whitespace only (preserves indentation) |
| `--strip-blank` | Remove blank lines |
| `--collapse` | Collapse whitespace runs to single space |
| `--dedup` | Remove duplicate lines |
| `--unformat` | Normalize smart quotes, dashes, spaces |

### Case

| Flag | Description |
|------|-------------|
| `--lower` | lowercase |
| `--upper` | UPPERCASE |
| `--title` | Title Case |
| `--sentence` | Sentence case |

### Sort

| Flag | Description |
|------|-------------|
| `--sort` | Sort lines A → Z |
| `--sort-r` | Sort lines Z → A |

### Lists

| Flag | Description |
|------|-------------|
| `--join SEP` | Join lines with separator |
| `--split SEP` | Split by separator into lines |
| `--prefix STR` | Add prefix to each line |
| `--suffix STR` | Add suffix to each line |
| `--wrap PRE SUF` | Wrap each line with prefix and suffix |

### Paste Destination

| Flag | Description |
|------|-------------|
| `--tohtml` | → Rich HTML (Gmail, Mail, Word, Notes) |
| `--toexcel` | → Excel-friendly (tables as TSV, strips markdown) |
| `--csv2md` | → CSV to Markdown table |
| `--csv2html` | → CSV to HTML table (Apple Notes) |
| `--md2csv` | → Markdown table to Excel TSV |
| `--md2html` | → Markdown table to HTML table |

### Options

| Flag | Description |
|------|-------------|
| `--no-copy` | Print to stdout instead of copying to clipboard |
| `--rich` | Force rich HTML clipboard copy |
| `-h, --help` | Show help |


## Other Platforms

### Linux (testing)

```bash
# Clone and install to PATH
git clone https://github.com/server-boss/clip-utility.git
sudo cp clip-utility/bin/clip clip-utility/bin/clip-tui /usr/local/bin/

# Install clipboard tool (pick one)
sudo apt install xclip        # X11
sudo apt install wl-clipboard  # Wayland
```

### Windows WSL-Only (testing)

Requires Windows Subsystem for Linux. If you don't have WSL installed:

```powershell
# Run in PowerShell as Administrator
wsl --install -d Ubuntu
```

After restarting your computer, open **PowerShell** and run `wsl` to launch Ubuntu. It will prompt you to create a username and password on first run. Once you see a `$` prompt, you're in Linux and ready to install clip.

Then install clip inside WSL:

```bash
# Fix locale (common on fresh WSL installs)
sudo locale-gen en_US.UTF-8

# Install dependencies
sudo apt update && sudo apt install -y fzf pandoc

# Clone and install
git clone https://github.com/server-boss/clip-utility.git
sudo cp clip-utility/bin/clip clip-utility/bin/clip-tui /usr/local/bin/
```

`clip` auto-detects WSL and uses PowerShell for clipboard access — no extra clipboard tools needed.

To launch `clip-tui` with a hotkey, create a desktop shortcut:

1. Right-click desktop → **New** → **Shortcut**
2. Set target to: `wsl.exe -e bash -lc clip-tui`
3. Click **Next**, name it "Clip TUI", click **Finish**
4. Right-click the shortcut → **Properties** → **Shortcut key** → press your desired key combo (e.g. `Ctrl+Alt+C`)


## License

MIT
