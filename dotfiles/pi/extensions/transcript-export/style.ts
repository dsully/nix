/** Liquid-glass look: translucent, blurred panels over a soft gradient; follows light/dark. */
export const STYLE = `
:root {
  --bg: #EEF1F7; --ink: #1D1D1F; --faded: #6E6E73; --accent: #007AFF; --red: #FF3B30;
  --blob-1: #C7D7FF; --blob-2: #F6D3EA; --blob-3: #C9EEDF;
  --glass: rgba(255, 255, 255, .55); --glass-tint: rgba(0, 122, 255, .10);
  --edge: rgba(255, 255, 255, .85); --edge-soft: rgba(255, 255, 255, .35); --shadow: rgba(25, 35, 70, .14);
  --line: rgba(0, 0, 0, .08); --code: rgba(255, 255, 255, .6); --mark: rgba(0, 122, 255, .22);
  --text: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", system-ui, sans-serif;
  --display: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", system-ui, sans-serif;
  --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
  --blur: blur(28px) saturate(180%);
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0B0C10; --ink: #F5F5F7; --faded: #98989F; --accent: #0A84FF; --red: #FF453A;
    --blob-1: #1C2A5C; --blob-2: #43203F; --blob-3: #123B33;
    --glass: rgba(40, 42, 52, .45); --glass-tint: rgba(10, 132, 255, .16);
    --edge: rgba(255, 255, 255, .16); --edge-soft: rgba(255, 255, 255, .05); --shadow: rgba(0, 0, 0, .45);
    --line: rgba(255, 255, 255, .09); --code: rgba(0, 0, 0, .32); --mark: rgba(10, 132, 255, .35);
  }
}
@media (prefers-reduced-transparency: reduce) {
  :root { --glass: var(--bg); --blur: none; }
}

* { box-sizing: border-box; }
html { -webkit-text-size-adjust: 100%; scroll-behavior: smooth; }
body {
  margin: 0; color: var(--ink); font: 16px/1.6 var(--text); -webkit-font-smoothing: antialiased;
  background-color: var(--bg);
  background-image:
    radial-gradient(60rem 40rem at 8% -5%, var(--blob-1), transparent 70%),
    radial-gradient(50rem 36rem at 105% 10%, var(--blob-2), transparent 70%),
    radial-gradient(56rem 40rem at 60% 110%, var(--blob-3), transparent 70%);
  background-attachment: fixed;
}
::selection { background: var(--mark); }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

.masthead, .prompt, .toc, .tool, .activity > summary, .thinking > summary, .summary, figure.code {
  background: var(--glass);
  -webkit-backdrop-filter: var(--blur); backdrop-filter: var(--blur);
  box-shadow: inset 0 1px 0 var(--edge), inset 0 0 0 1px var(--edge-soft), 0 12px 32px -14px var(--shadow);
}

.page { display: grid; grid-template-columns: minmax(0, 1fr) min(46rem, 100% - 2rem) minmax(0, 1fr); padding: 3rem 0 6rem; }
main { grid-column: 2; grid-row: 1; min-width: 0; }

.masthead { margin-bottom: 3rem; padding: 2rem 2.2rem 1.8rem; border-radius: 28px; }
.kicker { margin: 0 0 .6rem; font: 600 .72rem/1 var(--text); letter-spacing: .08em; text-transform: uppercase; color: var(--accent); }
h1 {
  margin: 0 0 1.4rem; font: 700 clamp(1.8rem, 4vw, 2.5rem)/1.12 var(--display); letter-spacing: -.022em;
  text-wrap: balance; overflow-wrap: anywhere;
}
.meta { display: grid; grid-template-columns: max-content 1fr; gap: .3rem 1.5rem; margin: 0; font-size: .84rem; }
.meta div { display: contents; }
.meta dt { color: var(--faded); }
.meta dd { margin: 0; overflow-wrap: anywhere; font-variant-numeric: tabular-nums; }

.turn { margin: 0 0 2.25rem; scroll-margin-top: 1.5rem; }
.who { display: flex; gap: .55rem; align-items: baseline; margin: 0 0 .55rem; font: 600 .78rem/1 var(--text); color: var(--faded); }
.who time { font-weight: 400; font-variant-numeric: tabular-nums; opacity: .8; }
.user { display: flex; flex-direction: column; align-items: flex-end; }
.user .who { flex-direction: row-reverse; }
.prompt {
  max-width: 88%; margin: 0 0 .75rem; padding: .85rem 1.15rem; border-radius: 22px 22px 6px 22px;
  background-image: linear-gradient(var(--glass-tint), var(--glass-tint)); white-space: pre-wrap; overflow-wrap: anywhere; transition: box-shadow .3s ease;
}
:target .prompt { box-shadow: inset 0 1px 0 var(--edge), 0 0 0 3px var(--mark), 0 12px 32px -14px var(--shadow); }
.user img.shot { max-width: 88%; }

.body > :first-child { margin-top: 0; }
.body > :last-child { margin-bottom: 1rem; }
p, ul, ol, blockquote, pre, figure, .table { margin: 0 0 1rem; }
h3, h4, h5, h6 { font-family: var(--display); line-height: 1.3; margin: 1.6rem 0 .55rem; letter-spacing: -.01em; text-wrap: balance; }
h3 { font-size: 1.22rem; } h4 { font-size: 1.06rem; } h5, h6 { font-size: 1rem; }
ul, ol { padding-left: 1.4rem; }
li { margin: .2rem 0; }
li::marker { color: var(--faded); }
li > p { margin: 0; }
li > ul, li > ol { margin: .2rem 0; }
blockquote { padding-left: 1rem; border-left: 3px solid var(--line); color: var(--faded); }
hr { border: 0; border-top: 1px solid var(--line); margin: 2rem 0; }

code { font-family: var(--mono); font-size: .86em; background: var(--code); border-radius: 6px; padding: .1em .35em; overflow-wrap: anywhere; }
pre {
  background: var(--code); border-radius: 14px; padding: .85rem 1rem; overflow: auto;
  font: .8rem/1.55 var(--mono); tab-size: 4; box-shadow: inset 0 0 0 1px var(--line);
}
pre code { background: none; padding: 0; font-size: inherit; overflow-wrap: normal; }
figure.code { border-radius: 16px; padding: .3rem; }
figure.code figcaption { padding: .25rem .7rem .35rem; font: 600 .68rem/1 var(--text); letter-spacing: .06em; text-transform: uppercase; color: var(--faded); }
figure.code pre { margin: 0; border-radius: 12px; }
.table { overflow-x: auto; }
table { border-collapse: collapse; font-size: .88rem; }
th, td { border-bottom: 1px solid var(--line); padding: .45rem .8rem .45rem 0; text-align: left; vertical-align: top; }
th { font-weight: 600; }
img.shot { display: block; max-width: 100%; height: auto; margin: 0 0 1rem; border-radius: 14px; box-shadow: 0 10px 30px -12px var(--shadow); }

summary { cursor: pointer; list-style: none; }
summary::-webkit-details-marker { display: none; }
summary::before {
  content: ""; flex: none; display: inline-block; width: .4em; height: .4em; margin-right: .65em;
  border-right: 1.5px solid currentColor; border-bottom: 1.5px solid currentColor;
  transform: translateY(-.12em) rotate(-45deg); transition: transform .2s ease; opacity: .6;
}
details[open] > summary::before { transform: translateY(-.2em) rotate(45deg); }
summary:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

.activity, .thinking { margin: 0 0 1rem; }
.activity > summary, .thinking > summary {
  display: inline-flex; align-items: baseline; max-width: 100%; padding: .38rem .95rem; border-radius: 999px;
  font-size: .8rem; color: var(--faded);
}
.activity-count { flex: none; font-weight: 600; color: var(--ink); margin-right: .6rem; }
.activity-detail { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.steps { margin: .6rem 0 0 1rem; padding-left: 1rem; border-left: 2px solid var(--line); }
.thought { margin: .6rem 0 0 1rem; padding-left: 1rem; border-left: 2px solid var(--line); color: var(--faded); font-size: .93rem; }

.tool { margin: 0 0 .5rem; border-radius: 16px; overflow: hidden; }
.steps .tool { -webkit-backdrop-filter: none; backdrop-filter: none; }
.tool > summary { display: flex; align-items: baseline; padding: .5rem .95rem; font: .78rem/1.5 var(--mono); color: var(--faded); }
.tool-name { flex: none; color: var(--accent); font-weight: 600; margin-right: .7rem; }
.tool-arg { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--ink); }
.tool-meta { flex: none; margin-left: .8rem; font: .7rem/1.5 var(--text); font-variant-numeric: tabular-nums; }
.tool.error .tool-name, .tool.error .tool-meta { color: var(--red); }
.tool.error { box-shadow: inset 0 1px 0 var(--edge), inset 0 0 0 1px color-mix(in srgb, var(--red) 40%, transparent), 0 12px 32px -14px var(--shadow); }
.tool-body { padding: .2rem .6rem .1rem; }
.tool-body pre { max-height: 32rem; margin-bottom: .6rem; }
.tool-input { white-space: pre-wrap; overflow-wrap: anywhere; box-shadow: inset 3px 0 0 var(--accent), inset 0 0 0 1px var(--line); }
.clip { margin: -.2rem 0 .7rem .4rem; font-size: .76rem; font-style: italic; color: var(--faded); }

.summary { margin: 0 0 2.25rem; padding: .8rem 1.1rem; border-radius: 20px; }
.summary > summary { display: flex; align-items: baseline; font: 600 .78rem/1.5 var(--text); color: var(--faded); }
.summary .body { margin-top: .8rem; font-size: .94rem; }

.toc {
  grid-column: 1; grid-row: 1; justify-self: end; align-self: start; position: sticky; top: 3rem;
  width: 15rem; max-height: calc(100vh - 6rem); overflow: auto; margin-right: 2rem; padding: 1.1rem 1.1rem .6rem;
  border-radius: 22px; font-size: .8rem; line-height: 1.4;
}
.toc h2 { margin: 0 0 .8rem; font: 600 .72rem/1 var(--text); letter-spacing: .08em; text-transform: uppercase; color: var(--faded); }
.toc ol { list-style: none; margin: 0; padding: 0; counter-reset: prompt; }
.toc li { counter-increment: prompt; display: flex; gap: .5rem; margin: 0 0 .55rem; }
.toc li::before { content: counter(prompt); flex: none; min-width: 1.4em; text-align: right; color: var(--faded); font-variant-numeric: tabular-nums; }
.toc a { color: var(--ink); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.toc a:hover { color: var(--accent); text-decoration: none; }

footer { margin-top: 4rem; font-size: .76rem; color: var(--faded); text-align: center; }

@media (max-width: 78rem) { .toc { display: none; } }
@media (max-width: 40rem) { body { font-size: 15px; } .page { padding: 1.5rem 0 4rem; } .masthead { padding: 1.4rem; border-radius: 22px; } }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } summary::before, .prompt { transition: none; } }
@media print {
  :root { --bg: #fff; --glass: #fff; --glass-tint: #f2f2f7; --code: #f5f5f7; --blur: none; }
  body { background: #fff; }
  .masthead, .prompt, .toc, .tool, .activity > summary, .thinking > summary, .summary, figure.code { box-shadow: inset 0 0 0 1px #d2d2d7; }
  .toc { display: none; }
  .page { display: block; padding: 0; }
  .tool, pre, .prompt { break-inside: avoid; }
  .tool-body pre { max-height: none; }
}
`;
