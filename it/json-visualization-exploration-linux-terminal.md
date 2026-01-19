# JSON visualization / exploration (Linux + terminal)

## JSON Crack (graph visualization)
- Works on Linux without VS Code: use the web app in any browser.
- VS Code extension is optional.
- For sensitive JSON: run JSON Crack locally (Docker) and open in browser.

Keywords: jsoncrack, visualize json, graph, browser, self-host, docker

## Terminal-first alternatives (CLI/TUI)
1) jless
- Terminal JSON viewer (expand/collapse, search).
- Use: `jless file.json`
Keywords: jless, tui, fold, search

2) fx
- Interactive terminal JSON viewer/processor (good with pipes).
- Use: `cat file.json | fx`
Keywords: fx, interactive, pipe, streaming

3) jnv
- Interactive JSON viewer with live jq filter editing.
- Use: `cat file.json | jnv`
Keywords: jnv, jq, interactive filter

4) jiq
- Interactive drill-down using jq queries (requires jq).
- Use: `cat file.json | jiq`
Keywords: jiq, jq, drill-down

5) gron
- Flattens JSON into “path = value” lines for grep/searching.
- Use: `gron file.json | less` (then search in `less`)
Keywords: gron, flatten, grep, paths

## Quick pick
- Need graph visualization: JSON Crack (browser; optionally local via Docker).
- Need terminal exploration: jless or fx.
- Need jq-centric exploration: jnv or jiq.
- Need to find paths fast: gron.
