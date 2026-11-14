"""Convert the MealMate API guide Markdown file to a styled HTML file.

The HTML is then printed to PDF by Microsoft Edge headless mode.
This script intentionally uses only the Python standard library.
"""

from __future__ import annotations

import html
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "API_UI_CONNECTION_GUIDE.md"
TARGET_HTML = ROOT / "docs" / "API_UI_CONNECTION_GUIDE.html"


def resolve_paths(argv: list[str]) -> tuple[Path, Path]:
    """Resolve source Markdown and target HTML from CLI arguments."""
    source = Path(argv[1]) if len(argv) > 1 else SOURCE
    if not source.is_absolute():
        source = (Path.cwd() / source).resolve()

    if len(argv) > 2:
        target = Path(argv[2])
        if not target.is_absolute():
            target = (Path.cwd() / target).resolve()
    else:
        target = source.with_suffix(".html")

    return source, target


def document_title(markdown: str, fallback: str) -> str:
    """Use the first level-1 heading as the HTML title when available."""
    match = re.search(r"^#\s+(.+)$", markdown, re.MULTILINE)
    if not match:
        return fallback
    title = re.sub(r"[*_`]", "", match.group(1)).strip()
    return title or fallback


def inline(text: str) -> str:
    """Render inline Markdown (bold, italic, code, links)."""
    parts = text.split("`")
    rendered: list[str] = []

    for index, part in enumerate(parts):
        if index % 2 == 1:
            # Inline code must not be processed for bold/italic.
            rendered.append(f"<code>{html.escape(part, quote=False)}</code>")
            continue

        escaped = html.escape(part, quote=False)

        # Links: [label](url)
        escaped = re.sub(
            r"\[([^\]]+)\]\(([^)]+)\)",
            r'<a href="\2">\1</a>',
            escaped,
        )

        # Bold: **text**
        escaped = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", escaped)

        # Italic: *text* (avoid matching the ** handled above)
        escaped = re.sub(r"(?<!\*)\*([^*\n]+?)\*(?!\*)", r"<em>\1</em>", escaped)

        rendered.append(escaped)

    return "".join(rendered)


def split_table_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def is_table_separator(line: str) -> bool:
    cells = split_table_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells)


def render_table(lines: list[str]) -> str:
    header = split_table_row(lines[0])
    body_lines = lines[2:] if len(lines) > 1 and is_table_separator(lines[1]) else lines[1:]

    out = ['<table>', "<thead><tr>"]
    for cell in header:
        out.append(f"<th>{inline(cell)}</th>")
    out.append("</tr></thead><tbody>")

    for line in body_lines:
        cells = split_table_row(line)
        out.append("<tr>")
        for cell in cells:
            out.append(f"<td>{inline(cell)}</td>")
        out.append("</tr>")

    out.append("</tbody></table>")
    return "".join(out)


def render_list_item(line: str) -> str:
    match = re.match(r"^(\s*)([-*+]|\d+\.)\s+(.*)$", line)
    if not match:
        return ""

    indent = len(match.group(1).replace("\t", "    "))
    marker = match.group(2)
    text = match.group(3)

    checkbox = re.match(r"^\[([ xX])\]\s+(.*)$", text)
    if checkbox:
        checked = checkbox.group(1).lower() == "x"
        text = f"{'☑' if checked else '☐'} {checkbox.group(2)}"

    if marker.endswith("."):
        bullet = marker
    else:
        bullet = "•"

    padding = 1.35 + (indent // 2) * 1.15
    return (
        f'<div class="list-item" style="padding-left:{padding:.2f}em">'
        f'<span class="list-marker">{html.escape(bullet)}</span>'
        f"<span>{inline(text)}</span></div>"
    )


def convert(markdown: str) -> str:
    lines = markdown.splitlines()
    out: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Fenced code block
        if line.strip().startswith("```"):
            language = line.strip()[3:].strip()
            i += 1
            code_lines: list[str] = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code_lines.append(lines[i])
                i += 1
            i += 1  # skip closing fence
            code = html.escape("\n".join(code_lines), quote=False)
            css_class = f' class="language-{html.escape(language)}"' if language else ""
            out.append(f"<pre><code{css_class}>{code}</code></pre>")
            continue

        # Blank line
        if not line.strip():
            i += 1
            continue

        # Heading
        heading = re.match(r"^(#{1,6})\s+(.*)$", line)
        if heading:
            level = len(heading.group(1))
            out.append(f"<h{level}>{inline(heading.group(2).strip())}</h{level}>")
            i += 1
            continue

        # Horizontal rule
        if re.fullmatch(r"\s*(---+|\*\*\*+|___+)\s*", line):
            out.append("<hr/>")
            i += 1
            continue

        # Table
        if "|" in line and i + 1 < len(lines):
            next_line = lines[i + 1]
            if "|" in next_line and is_table_separator(next_line):
                table_lines = [line, next_line]
                i += 2
                while i < len(lines) and "|" in lines[i] and lines[i].strip():
                    table_lines.append(lines[i])
                    i += 1
                out.append(render_table(table_lines))
                continue

        # Blockquote
        if line.lstrip().startswith(">"):
            quote_lines: list[str] = []
            while i < len(lines) and lines[i].lstrip().startswith(">"):
                quote_lines.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append(f"<blockquote>{inline(' '.join(quote_lines))}</blockquote>")
            continue

        # List block
        if re.match(r"^\s*([-*+]|\d+\.)\s+", line):
            items: list[str] = []
            while i < len(lines):
                current = lines[i]
                if not current.strip():
                    # A blank line ends the list unless the next line is another item.
                    if i + 1 < len(lines) and re.match(
                        r"^\s*([-*+]|\d+\.)\s+", lines[i + 1]
                    ):
                        i += 1
                        continue
                    break
                if not re.match(r"^\s*([-*+]|\d+\.)\s+", current):
                    break
                items.append(render_list_item(current))
                i += 1
            out.append('<div class="list-block">' + "".join(items) + "</div>")
            continue

        # Paragraph
        paragraph_lines: list[str] = []
        while i < len(lines):
            current = lines[i]
            if not current.strip():
                break
            if current.strip().startswith("```"):
                break
            if re.match(r"^(#{1,6})\s+", current):
                break
            if re.fullmatch(r"\s*(---+|\*\*\*+|___+)\s*", current):
                break
            if re.match(r"^\s*([-*+]|\d+\.)\s+", current):
                break
            if current.lstrip().startswith(">"):
                break
            if (
                "|" in current
                and i + 1 < len(lines)
                and "|" in lines[i + 1]
                and is_table_separator(lines[i + 1])
            ):
                break
            paragraph_lines.append(current.strip())
            i += 1

        if paragraph_lines:
            out.append(f"<p>{inline(' '.join(paragraph_lines))}</p>")

    return "\n".join(out)


CSS = """
@page {
  size: A4;
  margin: 17mm 14mm 18mm 14mm;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: "Myanmar Text", "Pyidaungsu", "Noto Sans Myanmar",
    "Segoe UI", sans-serif;
  font-size: 10.4pt;
  line-height: 1.68;
  color: #1f2937;
  background: #ffffff;
  -webkit-print-color-adjust: exact;
  print-color-adjust: exact;
}

h1 {
  margin: 0 0 10px;
  font-size: 23pt;
  line-height: 1.3;
  color: #06462a;
  border-bottom: 4px solid #ff7900;
  padding-bottom: 10px;
}

h2 {
  margin: 26px 0 10px;
  font-size: 16.5pt;
  line-height: 1.35;
  color: #06462a;
  border-left: 6px solid #ff7900;
  padding-left: 10px;
  page-break-after: avoid;
}

h3 {
  margin: 20px 0 8px;
  font-size: 13pt;
  color: #123d22;
  page-break-after: avoid;
}

h4 {
  margin: 16px 0 6px;
  font-size: 11.4pt;
  color: #1f4d2e;
  page-break-after: avoid;
}

p {
  margin: 8px 0;
  orphans: 3;
  widows: 3;
}

a {
  color: #0b63b6;
  text-decoration: none;
}

hr {
  border: 0;
  border-top: 1px solid #d7ddd3;
  margin: 18px 0;
}

blockquote {
  margin: 12px 0;
  padding: 9px 13px;
  background: #f3f9e9;
  border-left: 5px solid #17852a;
  border-radius: 0 6px 6px 0;
  color: #26402e;
}

blockquote p {
  margin: 0;
}

code {
  font-family: Consolas, "Cascadia Mono", "Courier New", monospace;
}

:not(pre) > code {
  background: #eef2f7;
  color: #b42318;
  border: 1px solid #e3e8ef;
  border-radius: 3px;
  padding: 0.5px 4px;
  font-size: 9.1pt;
  word-break: break-word;
}

pre {
  margin: 10px 0 14px;
  padding: 11px 13px;
  background: #0f172a;
  color: #e2e8f0;
  border-radius: 7px;
  font-size: 8.35pt;
  line-height: 1.48;
  white-space: pre-wrap;
  word-break: break-word;
  overflow-wrap: anywhere;
  page-break-inside: avoid;
}

pre code {
  color: inherit;
  background: transparent;
  padding: 0;
  border: 0;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin: 10px 0 16px;
  font-size: 8.9pt;
  line-height: 1.45;
  table-layout: fixed;
  page-break-inside: avoid;
}

th {
  background: #06462a;
  color: #ffffff;
  font-weight: 700;
  text-align: left;
}

th,
td {
  border: 1px solid #d1d5db;
  padding: 5px 7px;
  vertical-align: top;
  word-break: break-word;
  overflow-wrap: anywhere;
}

tbody tr:nth-child(even) td {
  background: #f8fafc;
}

.list-block {
  margin: 6px 0 10px;
}

.list-item {
  display: flex;
  gap: 0.45em;
  margin: 2.5px 0;
  align-items: flex-start;
}

.list-marker {
  flex: 0 0 auto;
  color: #17852a;
  font-weight: 700;
}

.list-item > span:last-child {
  flex: 1 1 auto;
}

strong {
  color: #111827;
}
"""


def main() -> None:
    source, target_html = resolve_paths(sys.argv)

    if not source.exists():
        raise SystemExit(f"Source Markdown not found: {source}")

    markdown = source.read_text(encoding="utf-8")
    body = convert(markdown)
    title = document_title(markdown, source.stem.replace("_", " ").title())

    generated = datetime.now().strftime("%Y-%m-%d %H:%M")
    document = f"""<!DOCTYPE html>
<html lang="my">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>{html.escape(title)}</title>
<style>{CSS}</style>
</head>
<body>
{body}
<footer style="margin-top:28px;padding-top:10px;border-top:1px solid #d7ddd3;color:#6b7280;font-size:8.5pt;">
Generated from <code>lib/</code> and backend API contract · {generated}
</footer>
</body>
</html>
"""

    target_html.write_text(document, encoding="utf-8")
    print(target_html)


if __name__ == "__main__":
    main()
