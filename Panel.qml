import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "lib/Model.js" as Model

// The settings popup anchored under the bar icon. Mouse acceleration and
// pointer speed live in ~/.config/hypr/input.lua as a Lua table; Model.js
// owns the regex surgery on that file's text, this file owns the UI and
// applying it (write + hyprctl reload).
Panel {
  id: root
  moduleName: "io.github.tseitz.mouse-settings"
  ipcTarget: "io.github.tseitz.mouse-settings"

  property var anchorItem: null
  property var hostWidget: null

  readonly property string inputPath: Quickshell.env("HOME") + "/.config/hypr/input.lua"

  property string accelProfile: "adaptive"
  property real sensitivity: 0
  property real scrollFactor: 1
  property string errorText: ""
  property string lastBackupStamp: ""

  readonly property bool accelOn: accelProfile === "adaptive"

  function syncFromText(text) {
    var parsed = Model.parseInput(text)
    root.accelProfile = parsed.accelProfile
    root.sensitivity = parsed.sensitivity
    root.scrollFactor = parsed.scrollFactor
  }

  // One backup per day, taken just before the first write of the session —
  // matches the omarchy convention of timestamped input.lua.bak.<epoch>
  // files, without spawning one per slider tick while dragging.
  function backupOnce(currentText) {
    var stamp = Qt.formatDateTime(new Date(), "yyyyMMdd")
    if (root.lastBackupStamp === stamp) return
    root.lastBackupStamp = stamp
    backupProc.command = ["cp", root.inputPath, root.inputPath + ".bak." + Math.floor(Date.now() / 1000)]
    backupProc.running = true
  }

  function applyState(accel, sens, scroll) {
    var updated = Model.buildInput(inputFile.text(), accel, sens, scroll)
    if (updated === null) {
      root.errorText = "Could not find the input settings block in input.lua"
      return
    }
    root.accelProfile = accel
    root.sensitivity = sens
    root.scrollFactor = scroll
    backupOnce(inputFile.text())
    inputFile.setText(updated)
    reloadProc.running = true
  }

  FileView {
    id: inputFile
    path: root.inputPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.syncFromText(text())
    onLoadFailed: root.errorText = "Could not read " + root.inputPath
    onFileChanged: reload()
  }

  Process {
    id: backupProc
    stdout: StdioCollector { waitForEnd: true }
  }

  Process {
    id: reloadProc
    command: ["sh", "-c", "hyprctl reload >/dev/null 2>&1; hyprctl configerrors"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var output = String(text || "").trim()
        root.errorText = (output !== "" && output.toLowerCase() !== "ok") ? output : ""
      }
    }
  }

  Timer {
    id: speedDebounce
    interval: 150
    onTriggered: root.applyState(root.accelProfile, speedSlider.liveValue, root.scrollFactor)
  }

  Timer {
    id: scrollDebounce
    interval: 150
    onTriggered: root.applyState(root.accelProfile, root.sensitivity, scrollSlider.liveValue)
  }

  PopupCard {
    id: card
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root
    contentWidth: card.fittedContentWidth(Style.space(300))
    contentHeight: card.fittedContentHeight(column.implicitHeight)
    open: root.opened

    Column {
      id: column
      width: parent.width
      spacing: Style.spacing.lg

      Text {
        text: "Mouse"
        color: root.barForeground
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      PanelSeparator { foreground: root.barForeground }

      Row {
        width: parent.width
        spacing: Style.spacing.md

        Column {
          width: parent.width - accelSwitch.width - parent.spacing
          spacing: Style.spacing.xs

          Text {
            width: parent.width
            text: "Mouse acceleration"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }

          Text {
            width: parent.width
            text: root.accelOn
              ? "Speeds up the faster you move it"
              : "Flat, 1:1 tracking — better for gaming"
            color: Qt.darker(root.barForeground, 1.4)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        ToggleSwitch {
          id: accelSwitch
          anchors.verticalCenter: parent.verticalCenter
          checked: root.accelOn
          foreground: root.barForeground
          onToggled: root.applyState(root.accelOn ? "flat" : "adaptive", root.sensitivity, root.scrollFactor)
        }
      }

      PanelSeparator { foreground: root.barForeground }

      Column {
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          text: "Pointer speed"
          color: root.barForeground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        PanelSlider {
          id: speedSlider
          width: parent.width
          bar: root.bar
          minimum: -1
          maximum: 1
          step: 0.05
          value: root.sensitivity
          onMoved: speedDebounce.restart()
          onReleased: function(v) {
            speedDebounce.stop()
            root.applyState(root.accelProfile, v, root.scrollFactor)
          }
        }

        MinMaxLabels {
          width: parent.width
          foreground: root.barForeground
          leftText: "Slower"
          rightText: "Faster"
        }
      }

      Column {
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          text: "Scroll speed"
          color: root.barForeground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        PanelSlider {
          id: scrollSlider
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 2
          step: 0.05
          value: root.scrollFactor
          onMoved: scrollDebounce.restart()
          onReleased: function(v) {
            scrollDebounce.stop()
            root.applyState(root.accelProfile, root.sensitivity, v)
          }
        }

        MinMaxLabels {
          width: parent.width
          foreground: root.barForeground
          leftText: "Slower"
          rightText: "Faster"
        }
      }

      PanelSeparator { foreground: root.barForeground }

      Row {
        width: parent.width
        layoutDirection: Qt.RightToLeft

        Button {
          text: "Reset to defaults"
          foreground: root.barForeground
          bordered: true
          onClicked: root.applyState("adaptive", 0, 1)
        }
      }

      Text {
        visible: root.errorText !== ""
        width: parent.width
        text: root.errorText
        color: Color.urgent
        wrapMode: Text.WordWrap
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
