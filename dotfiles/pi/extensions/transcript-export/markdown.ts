/**
 * Markdown to HTML for the subset models write: fences, headings, lists, quotes, tables, rules, inline styles, links.
 * Every piece of source text is HTML-escaped; raw HTML in the source shows as text.
 */

export function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}

export function isSafeLink(url: string): boolean {
  return /^(https?:\/\/|mailto:|#)/i.test(url);
}

const FENCE = /^ {0,3}(`{3,}|~{3,})\s*([^\s`]*)/;
const HEADING = /^ {0,3}(#{1,6})\s+(.*?)(?:\s+#+)?\s*$/;
const RULE = /^ {0,3}([-*_])(?:\s*\1){2,}\s*$/;
const QUOTE = /^ {0,3}> ?/;
const ITEM = /^( *)([-*+]|\d{1,9}[.)])\s+(.*)$/;
const TABLE_DIVIDER = /^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$/;

/** `headingOffset` shifts heading levels so the page keeps its own h1/h2. */
export function markdownToHtml(source: string, headingOffset = 2): string {
  return blocks(source.replace(/\r\n?/g, "\n").split("\n"), headingOffset);
}

function blocks(lines: string[], offset: number): string {
  const out: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (!line.trim()) {
      i++;
      continue;
    }

    const fence = FENCE.exec(line);
    if (fence) {
      const [marker, lang] = [fence[1], fence[2]];
      const body: string[] = [];
      i++;
      while (
        i < lines.length &&
        !new RegExp(`^ {0,3}${marker[0] === "`" ? "`" : "~"}{${marker.length},}\\s*$`).test(lines[i])
      ) {
        body.push(lines[i++]);
      }
      i++;
      const pre = `<pre><code>${escapeHtml(body.join("\n"))}</code></pre>`;
      out.push(lang ? `<figure class="code"><figcaption>${escapeHtml(lang)}</figcaption>${pre}</figure>` : pre);
      continue;
    }

    const heading = HEADING.exec(line);
    if (heading) {
      const level = Math.min(heading[1].length + offset, 6);
      out.push(`<h${level}>${inline(heading[2])}</h${level}>`);
      i++;
      continue;
    }

    if (RULE.test(line)) {
      out.push("<hr>");
      i++;
      continue;
    }

    if (QUOTE.test(line)) {
      const body: string[] = [];
      while (i < lines.length && lines[i].trim() && QUOTE.test(lines[i])) body.push(lines[i++].replace(QUOTE, ""));
      out.push(`<blockquote>${blocks(body, offset)}</blockquote>`);
      continue;
    }

    if (line.includes("|") && i + 1 < lines.length && TABLE_DIVIDER.test(lines[i + 1]) && lines[i + 1].includes("-")) {
      const head = cells(line);
      i += 2;
      const rows: string[][] = [];
      while (i < lines.length && lines[i].includes("|") && lines[i].trim()) rows.push(cells(lines[i++]));
      const th = head.map((c) => `<th>${inline(c)}</th>`).join("");
      const tb = rows.map((r) => `<tr>${r.map((c) => `<td>${inline(c)}</td>`).join("")}</tr>`).join("");
      out.push(`<div class="table"><table><thead><tr>${th}</tr></thead><tbody>${tb}</tbody></table></div>`);
      continue;
    }

    const item = ITEM.exec(line);
    if (item) {
      const [ordered, indent] = [/\d/.test(item[2]), item[1].length];
      const items: string[][] = [];
      while (i < lines.length) {
        const m = ITEM.exec(lines[i]);
        if (!m || m[1].length !== indent || /\d/.test(m[2]) !== ordered) break;
        const content = [m[3]];
        const childIndent = indent + m[2].length + 1;
        i++;
        while (i < lines.length) {
          const next = lines[i];
          const indented = next.length - next.trimStart().length >= Math.min(childIndent, indent + 2);
          if (next.trim() && (indented || !startsBlock(next))) {
            content.push(
              indented ? next.slice(Math.min(childIndent, next.length - next.trimStart().length)) : next.trim(),
            );
            i++;
          } else if (
            !next.trim() &&
            i + 1 < lines.length &&
            lines[i + 1].length - lines[i + 1].trimStart().length > indent
          ) {
            content.push("");
            i++;
          } else {
            break;
          }
        }
        items.push(content);
      }
      const start = ordered ? parseInt(item[2], 10) : 1;
      const tag = ordered ? "ol" : "ul";
      const open = ordered && start !== 1 ? `<ol start="${start}">` : `<${tag}>`;
      out.push(open + items.map((c) => `<li>${listItem(c, offset)}</li>`).join("") + `</${tag}>`);
      continue;
    }

    const para: string[] = [];
    while (i < lines.length && lines[i].trim() && (para.length === 0 || !startsBlock(lines[i])))
      para.push(lines[i++].trim());
    out.push(`<p>${inline(para.join("\n"))}</p>`);
  }
  return out.join("\n");
}

function startsBlock(line: string): boolean {
  return FENCE.test(line) || HEADING.test(line) || RULE.test(line) || QUOTE.test(line) || ITEM.test(line);
}

/** An item's leading paragraph renders without `<p>`, so items read as list lines. */
function listItem(content: string[], offset: number): string {
  return blocks(content, offset).replace(/^<p>([\s\S]*?)<\/p>/, "$1");
}

function cells(row: string): string[] {
  return row
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split(/(?<!\\)\|/)
    .map((c) => c.trim());
}

/** Inline markdown on one block's text. Code spans and links are set aside first so later rules can't touch them. */
export function inline(text: string): string {
  const held: string[] = [];
  const hold = (html: string) => `\u0000${held.push(html) - 1}\u0000`;

  let s = text.replace(/\u0000/g, "");
  s = s.replace(/(`+)([\s\S]*?[^`])\1(?!`)/g, (_, _ticks, code: string) =>
    hold(`<code>${escapeHtml(code.trim() || code)}</code>`),
  );
  s = s.replace(/!\[([^\]]*)\]\([^)]*\)/g, (_, alt: string) => alt);
  s = s.replace(/\[([^\]]+)\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)/g, (_, label: string, url: string) =>
    isSafeLink(url) ? hold(`<a href="${escapeHtml(url)}">${styles(escapeHtml(label))}</a>`) : label,
  );
  s = s.replace(/<(https?:\/\/[^\s>]+)>|https?:\/\/[^\s<>()]*[^\s<>().,;:!?'"*_]/g, (whole, bracketed?: string) => {
    const url = bracketed ?? whole;
    return hold(`<a href="${escapeHtml(url)}">${escapeHtml(url)}</a>`);
  });
  s = styles(escapeHtml(s));
  // Held links can contain held code spans.
  while (s.includes("\u0000")) s = s.replace(/\u0000(\d+)\u0000/g, (_, n: string) => held[Number(n)]);
  return s;
}

function styles(s: string): string {
  return s
    .replace(/\*\*(?=\S)([\s\S]*?\S)\*\*/g, "<strong>$1</strong>")
    .replace(/(?<!\w)__(?=\S)([\s\S]*?\S)__(?!\w)/g, "<strong>$1</strong>")
    .replace(/(?<![\w*])\*(?=[^\s*])([^*]*?[^\s*])\*(?![\w*])/g, "<em>$1</em>")
    .replace(/(?<![\w_])_(?=[^\s_])([^_]*?[^\s_])_(?![\w_])/g, "<em>$1</em>")
    .replace(/~~(?=\S)([\s\S]*?\S)~~/g, "<del>$1</del>");
}
