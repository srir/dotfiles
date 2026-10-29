import { execFile } from "child_process";
import { homedir } from "os";
import { join } from "path";
import { promisify } from "util";
import { useEffect, useState } from "react";
import {
  Action,
  ActionPanel,
  Color,
  Icon,
  List,
  Toast,
  closeMainWindow,
  environment,
  getPreferenceValues,
  showToast,
} from "@raycast/api";
import { useCachedState } from "@raycast/utils";

const execFileAsync = promisify(execFile);

interface Preferences {
  rexPath: string;
  appName: string;
  aerospacePath: string;
}

const prefs = getPreferenceValues<Preferences>();
const REX = (
  prefs.rexPath ||
  "~/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
).replace(/^~(?=\/)/, homedir());
const APP = prefs.appName || "Rex Beta";
const AEROSPACE = prefs.aerospacePath || "/opt/homebrew/bin/aerospace";

// Foreground programs that count as agents even before they report a status.
const AGENT_PROGRAMS = new Set(["claude", "codex", "opencode", "amp", "gemini", "cursor-agent"]);

interface Pane {
  block_id: string;
  label: string;
  window_id: string;
  focused: boolean;
  app?: string;
  state?: string;
  msg?: string;
  title?: string;
  process?: string;
  cwd?: string;
}

interface Session {
  index: number;
  session_id: string;
  label: string;
  panes: Pane[];
}

function rex(args: string[]) {
  return execFileAsync(REX, args, { timeout: 10_000 });
}

// assets/gather.lua collects every session's panes and agent status in one `rex do` call.
// Lua can't tell an empty array from an empty object, so Rex encodes an empty
// list as {}: no sessions, or a session with no panes.
function asArray<T>(value: unknown): T[] {
  return Array.isArray(value) ? value : [];
}

// --autostart=false: listing shouldn't start a Rex server that isn't running.
async function loadAll(): Promise<Session[]> {
  const { stdout } = await rex(["--autostart=false", "do", join(environment.assetsPath, "gather.lua"), "--json"]);
  return asArray<Session>(JSON.parse(stdout).sessions).map((s) => ({ ...s, panes: asArray<Pane>(s.panes) }));
}

function isAgent(p: Pane): boolean {
  const program = p.process?.replace(/^-/, "");
  return Boolean(p.app) || (program !== undefined && AGENT_PROGRAMS.has(program));
}

function paneIcon(p: Pane): { source: Icon; tintColor: Color } {
  if (!isAgent(p)) return { source: Icon.Terminal, tintColor: Color.SecondaryText };
  switch (p.state) {
    case "working":
      return { source: Icon.CircleFilled, tintColor: Color.Yellow };
    case "blocked":
      return { source: Icon.CircleFilled, tintColor: Color.Red };
    case "done":
      return { source: Icon.CircleFilled, tintColor: Color.Blue };
    default:
      return { source: Icon.Circle, tintColor: Color.SecondaryText };
  }
}

async function rexWindows(): Promise<{ id: number; title: string }[]> {
  const { stdout } = await execFileAsync(AEROSPACE, ["list-windows", "--all", "--json"]);
  return (JSON.parse(stdout) as { "app-name": string; "window-id": number; "window-title": string }[])
    .filter((w) => w["app-name"] === APP)
    .map((w) => ({ id: w["window-id"], title: w["window-title"] ?? "" }));
}

// Rex titles each window "<tab title> - <session label>". One label can end
// another ("checks", "github checks"), so a window belongs to its longest match.
function windowShowing(
  windows: { id: number; title: string }[],
  sessions: Session[],
  target: Session,
): number | undefined {
  for (const w of windows) {
    const shown = sessions
      .filter((s) => w.title === s.label || w.title.endsWith(` - ${s.label}`))
      .sort((a, b) => b.label.length - a.label.length)[0];
    if (shown?.session_id === target.session_id) return w.id;
  }
}

async function jump(session: Session, pane: Pane | undefined, sessions: Session[]): Promise<void> {
  // If a Rex window already shows the session, raise it (from any space or monitor).
  const windowId = windowShowing(await rexWindows().catch(() => []), sessions, session);
  if (windowId !== undefined) {
    await execFileAsync(AEROSPACE, ["focus", "--window-id", `${windowId}`]);
  }
  if (pane) {
    // Server-side: make the pane's tab active and focus the pane.
    await rex(["focus", "-s", session.session_id, pane.block_id]);
  }
  if (windowId === undefined) {
    // Not on screen: show the session in the current window. Needs Remote Control turned on in Rex.
    const selectArgs = ["do", "session.select", `session_id=${session.session_id}`];
    if (pane) selectArgs.push(`window_id=${pane.window_id}`);
    await rex(selectArgs);
    await execFileAsync("/usr/bin/open", ["-a", APP]);
  }
}

function errorMessage(e: unknown): string {
  const err = e as { stderr?: string; message?: string };
  return (err.stderr || err.message || String(e)).trim();
}

export default function Command() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string>();
  const [filter, setFilter] = useCachedState<string>("filter", "all");

  useEffect(() => {
    loadAll()
      .then(setSessions)
      .catch((e) => setLoadError(errorMessage(e)))
      .finally(() => setIsLoading(false));
  }, []);

  async function onJump(session: Session, pane?: Pane) {
    await closeMainWindow();
    try {
      await jump(session, pane, sessions);
    } catch (e) {
      const message = errorMessage(e);
      const remoteControlOff = message.includes("Remote Control");
      await showToast({
        style: Toast.Style.Failure,
        title: remoteControlOff ? "Turn on Remote Control in Rex" : "Jump failed",
        message: remoteControlOff ? "Rex Settings → Rex Server → Remote Control" : message,
      });
    }
  }

  return (
    <List
      isLoading={isLoading}
      searchBarPlaceholder="Jump to a Rex session or pane…"
      searchBarAccessory={
        <List.Dropdown tooltip="Show" value={filter} onChange={setFilter}>
          <List.Dropdown.Item title="All Panes" value="all" />
          <List.Dropdown.Item title="Agent Panes" value="agents" />
        </List.Dropdown>
      }
    >
      <List.EmptyView
        icon={loadError ? Icon.Warning : Icon.AppWindowSidebarLeft}
        title={loadError ? "Couldn't reach Rex" : "No Rex sessions"}
        description={loadError ? `Is Rex running?\n\n${loadError}` : "Open Rex to start a session."}
      />
      {sessions.map((s) => {
        const panes = filter === "agents" ? s.panes.filter(isAgent) : s.panes;
        if (panes.length === 0 && filter === "agents") return null;
        return (
          <List.Section key={s.session_id} title={`${s.index} · ${s.label}`}>
            {panes.length === 0 ? (
              <List.Item
                title={s.label}
                icon={Icon.AppWindowSidebarLeft}
                keywords={[`${s.index}`]}
                actions={
                  <ActionPanel>
                    <Action title="Jump to Session" icon={Icon.ArrowRight} onAction={() => onJump(s)} />
                  </ActionPanel>
                }
              />
            ) : (
              panes.map((p) => (
                <List.Item
                  key={p.block_id}
                  title={p.title || p.label}
                  subtitle={p.msg || p.process}
                  keywords={[s.label, `${s.index}`, p.app, p.state, p.process].filter((k): k is string => Boolean(k))}
                  icon={paneIcon(p)}
                  accessories={[
                    ...(p.state ? [{ text: p.state }] : []),
                    ...(p.focused ? [{ icon: Icon.Eye, tooltip: "Focused pane in this session" }] : []),
                  ]}
                  actions={
                    <ActionPanel>
                      <Action title="Jump to Pane" icon={Icon.ArrowRight} onAction={() => onJump(s, p)} />
                      <Action
                        title="Jump to Session"
                        icon={Icon.AppWindowSidebarLeft}
                        shortcut={{ modifiers: ["cmd"], key: "return" }}
                        onAction={() => onJump(s)}
                      />
                      {p.cwd && <Action.CopyToClipboard title="Copy Working Directory" content={p.cwd} />}
                    </ActionPanel>
                  }
                />
              ))
            )}
          </List.Section>
        );
      })}
    </List>
  );
}
