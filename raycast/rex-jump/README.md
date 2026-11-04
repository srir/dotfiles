# Rex Jump

A Raycast command that lists every Rex session and pane, with agent status,
and jumps to the one you pick: it focuses the pane and shows its session in
Rex.app.

## Usage

Run **Jump to Rex Pane** in Raycast. Panes are grouped by session
(`1 · hex`, `2 · platform roadmap`, …). Type to fuzzy-filter by pane title,
session name, session number, agent, or status; hit Enter to jump to the pane,
or Cmd-Enter to jump to its session as it is. The dropdown switches between
**All Panes** and **Agent Panes**, and remembers your choice.

Each agent pane shows its status (working / blocked / done / idle) and what it
last reported doing. An eye marks the focused pane in each session.

## Requirements

- [AeroSpace](https://github.com/nikitabobko/AeroSpace), to raise the Rex
  window already showing a session.
- **Remote Control** turned on in Rex (Settings → Rex Server), for jumping to a
  session no window shows. Switching a window's session is an app action, and
  Rex.app refuses those from the `rex` CLI until Remote Control is on. Without
  it, that jump shows a toast saying so.

## Loading it into Raycast

```bash
cd rex-jump
npm install
npm run dev      # builds and registers the command in Raycast
```

As with herdr-jump, `npm run dev` is only needed to register the extension
and to hot-reload while editing. Quit it (Ctrl-C) once it's registered.

## How it works

- **Listing**: `rex do assets/gather.lua --json` runs one Lua script on the Rex
  server. It walks `session.list`, attaches to each session, reads
  `session.view` for its panes, and calls each terminal pane's `program_status`,
  `title`, and `process` methods. Agents report status through OSC 7501
  (Claude Code does this once `rex skill setup` has run). Panes running
  `claude`, `codex`, etc. count as agents even before they report.
- **Jumping**: Rex titles each window `<tab title> - <session label>`, so the
  extension reads `aerospace list-windows --all --json` for a Rex window already
  showing the session and raises it with `aerospace focus --window-id` (from any
  space or monitor). `rex focus -s <session> <block>` then focuses the pane on
  the server. Only when no window shows the session does it switch the current
  window, with `rex do session.select session_id=… window_id=…` and
  `open -a "Rex Beta"`.

## Config (command preferences)

- **rex binary**: defaults to the CLI inside Rex's bundled server.
- **Rex app name**: defaults to `Rex Beta`.
- **aerospace binary**: defaults to `/opt/homebrew/bin/aerospace`.

## Icon

`assets/icon.svg` is the source. Re-render the PNG Raycast uses with
`rsvg-convert -w 512 -h 512 assets/icon.svg -o assets/command-icon.png`.
