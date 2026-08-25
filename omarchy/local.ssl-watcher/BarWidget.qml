import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Certificate expiry indicator. All the reading and grading happens in
// ssl-watcher-bar, which hands back {text, tooltip, class}; this widget only
// paints the glyph and picks a color for it.
//
// The ok state deliberately leaves `foreground` at the bar default so the lock
// sits in the row of status icons looking like one of them, rather than
// announcing itself in green when there is nothing to announce.
BarWidget {
  id: root
  moduleName: "local.ssl-watcher"

  property string statusClass: "empty"
  property string glyph: "\uf233"
  property string details: "SSL watcher: no data yet"

  readonly property color warnColor: setting("warnColor", "#d7a65c")
  readonly property color criticalColor: setting("criticalColor", Color.urgent)
  readonly property color defaultColor: bar ? bar.barForeground : Color.foreground

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function recheck() {
    if (root.bar) root.bar.run("ssl-watcher-check --force")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Lets ssl-watcher-check repaint the bar the moment a check finishes,
  // instead of leaving it stale until the next poll.
  IpcHandler {
    target: "ssl-watcher"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Process {
    id: statusProc
    command: ["ssl-watcher-bar", "--plain"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var payload
        try {
          payload = JSON.parse(text || "{}")
        } catch (e) {
          root.statusClass = "empty"
          root.details = "ssl-watcher: could not read status"
          return
        }
        root.glyph = payload.text || "\uf233"
        root.details = payload.tooltip || ""
        root.statusClass = payload["class"] || "empty"
      }
    }
  }

  Timer {
    interval: root.setting("intervalMs", 300000)
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    // No slotSize/fontSize override: BarIconButton defaults to Style.bar.iconSlot
    // and Style.bar.iconFont, which is exactly what the tray icons use.
    foreground: root.statusClass === "critical" ? root.criticalColor
              : root.statusClass === "warn" ? root.warnColor
              : root.defaultColor
    dimmed: root.statusClass === "empty"
    tooltipText: root.details
    onPressed: root.recheck()
  }
}
