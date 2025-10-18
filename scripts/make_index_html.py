#!/usr/bin/env python3
import csv
import html
import os
import sys


def read_head(csv_path, limit):
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = []
        for i, row in enumerate(reader):
            rows.append(row)
            if i >= limit:
                break
    return rows


def render_table(title, rows):
    if not rows:
        return f"<h2>{html.escape(title)}</h2><p>Brak danych</p>"
    head, body = rows[0], rows[1:]
    out = [f"<h2>{html.escape(title)}</h2>", '<table>']
    out.append('<thead><tr>' + ''.join(f'<th>{html.escape(c)}</th>' for c in head) + '</tr></thead>')
    out.append('<tbody>')
    for r in body:
        out.append('<tr>' + ''.join(f'<td>{html.escape(c)}</td>' for c in r) + '</tr>')
    out.append('</tbody></table>')
    return '\n'.join(out)


def main():
    if len(sys.argv) < 3:
        print("Usage: make_index_html.py <csv_dir> <out_html> [preview_rows]", file=sys.stderr)
        sys.exit(1)
    csv_dir = sys.argv[1]
    out_html = sys.argv[2]
    preview_rows = int(sys.argv[3]) if len(sys.argv) > 3 else 50

    files = [f for f in os.listdir(csv_dir) if f.lower().endswith('.csv')]
    files.sort()

    parts = [
        '<!doctype html><html><head><meta charset="utf-8">',
        '<title>RIMS - Podgląd CSV</title>',
        '<style>body{font-family:sans-serif}table{border-collapse:collapse;margin-bottom:24px}td,th{border:1px solid #ccc;padding:4px 6px}h1{margin-top:0}</style>',
        '</head><body><h1>RIMS - Podgląd CSV</h1>'
    ]

    for name in files:
        path = os.path.join(csv_dir, name)
        rows = read_head(path, preview_rows)
        parts.append(render_table(name, rows))
        parts.append(f'<p><a href="csv/{html.escape(name)}">Pobierz CSV</a></p>')

    parts.append('</body></html>')

    os.makedirs(os.path.dirname(out_html), exist_ok=True)
    with open(out_html, 'w', encoding='utf-8') as f:
        f.write('\n'.join(parts))


if __name__ == '__main__':
    main()
