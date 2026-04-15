# clip

Composable clipboard transformer for macOS. Convert between rich text, markdown, HTML, CSV, and terminal output with a single command.

Copy from Claude Code and paste into Gmail with proper formatting. Copy from Excel and paste a clean markdown table into GitHub. Convert rich email threads into clean markdown for your notes.

Instead of manually cleaning up formatting every time you move text between apps, `clip` chains transforms together:

```bash
clip --claude --unwrap --tohtml    # Claude terminal → Gmail/Word/Notes
clip --md --rtrim --strip-blank    # Rich text → clean markdown
clip --claude --unwrap --toexcel   # Claude terminal → Excel
```

Includes an interactive TUI (`clip-tui`) with live preview, and a macOS dialog interface (`clip-menu`) for use with Apple Shortcuts.

### Interactive TUI with live preview

![clip-tui](assets/tui.png)

### Result pasted into Typora

![Rich paste result](assets/rich-paste.png)

## Install

### Homebrew (recommended)

```bash
brew tap server-boss/clip-utility
brew install clip-utility
```

### Dependencies

- **pandoc** (optional) — required for `--md` and `--tohtml` transforms. Install with `brew install pandoc`.
- **fzf** (optional) — required for `clip-tui`. Install with `brew install fzf`.

## Usage

```
clip [transform ...] [options]
echo "text" | clip [transform ...] [options]
clip-tui                              Interactive TUI with live preview
```

### Presets (common combos)

```bash
clip --claude --unwrap                 # Claude terminal → Markdown
clip --claude --unwrap --tohtml        # Claude terminal → Rich (Gmail/Mail/Word/Notes)
clip --claude --unwrap --toexcel       # Claude terminal → Excel
clip --md --rtrim --strip-blank        # Rich → Markdown
clip --tohtml                          # Markdown → Rich
```

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

## Interactive TUI

Run `clip-tui` for a full-screen interface with live preview. Requires `fzf`.

- **Tab** to toggle transforms on/off
- **Enter** to apply
- **Ctrl-C** to cancel

![clip-tui](assets/tui.png)

## Apple Shortcuts

Run `clip-menu` for a native macOS dialog interface. Create an Apple Shortcut with a single "Run Shell Script" action pointing to `clip-menu` and assign a keyboard shortcut.

| | |
|---|---|
| ![Main menu](assets/menu-main.png) | ![Format options](assets/menu-format.png) |
| ![Table options](assets/menu-tables.png) | |

### Shortcut setup

Create a new shortcut in Shortcuts.app with a "Run Shell Script" action. Set the script to the path of `clip-menu`, shell to `bash`, and input to "Clipboard". Assign a keyboard shortcut (e.g. `Option+Shift+C`) under the shortcut's details.

| | |
|---|---|
| ![Shortcut setup](assets/shortcut-setup.png) | ![Shortcut privacy](assets/shortcut-privacy.png) |

## How It Works

Transforms are applied left-to-right in the order you specify. The clipboard is read, piped through each transform, and the result is copied back.

For rich-text destinations (Gmail, Notes, Word), `clip` writes HTML to the macOS pasteboard via `NSPasteboard` with proper `<meta charset="utf-8">` and inline styles — so tables, bold, italic, and code blocks paste correctly.

## License

MIT
