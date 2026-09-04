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
  property bool showAdvanced: false

  readonly property bool accelOn: accelProfile === "adaptive"

  // Slider bounds/step are user-tunable (the gear icon) and persist via
  // `omarchy bar set`, inline on this widget's shell.json entry. Clamped to
  // Hyprland's actual valid ranges so a hand-edited shell.json can't hand a
  // slider a bound Hyprland would reject.
  readonly property real pointerMin: Model.clamp(root.setting("pointerMin", -1), -1, 1)
  readonly property real pointerMax: Model.clamp(root.setting("pointerMax", 1), -1, 1)
  readonly property real scrollMin: Model.clamp(root.setting("scrollMin", 0.1), 0, 2)
  readonly property real scrollMax: Model.clamp(root.setting("scrollMax", 2), 0, 2)
  readonly property real sliderStep: Model.clamp(root.setting("sliderStep", 0.05), 0.01, 0.5)

  // A single Process handles every advanced-field edit; queuing keeps rapid
  // edits (or resetAdvanced's five at once) from starting a second `omarchy
  // bar set` while one is still running.
  property var advancedQueue: []

  function runNextAdvanced() {
    if (advancedQueue.length === 0) return
    var next = advancedQueue.shift()
    advancedProc.command = ["omarchy", "bar", "set", root.moduleName, next.key, next.value.toFixed(2), "--json"]
    advancedProc.running = true
  }

  function setAdvanced(key, value) {
    advancedQueue.push({ key: key, value: value })
    if (!advancedProc.running) runNextAdvanced()
  }

  function resetAdvanced() {
    setAdvanced("pointerMin", -1)
    setAdvanced("pointerMax", 1)
    setAdvanced("scrollMin", 0.1)
    setAdvanced("scrollMax", 2)
    setAdvanced("sliderStep", 0.05)
  }

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
    id: advancedProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: if (!running) root.runNextAdvanced()
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
    contentHeight: card.fittedContentHeight(
      root.showAdvanced ? advancedColumn.implicitHeight : mainColumn.implicitHeight)
    open: root.opened

    Column {
      id: mainColumn
      visible: !root.showAdvanced
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
          minimum: root.pointerMin
          maximum: root.pointerMax
          step: root.sliderStep
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
          minimum: root.scrollMin
          maximum: root.scrollMax
          step: root.sliderStep
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

      Item {
        width: parent.width
        height: Math.max(resetButton.implicitHeight, advancedButton.implicitHeight)

        Button {
          id: resetButton
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Reset to defaults"
          foreground: root.barForeground
          bordered: true
          onClicked: root.applyState("adaptive", 0, 1)
        }

        GearButton {
          id: advancedButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰒓"
          tooltipText: "Advanced: min, max, step"
          foreground: root.barForeground
          onClicked: root.showAdvanced = true
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

    Column {
      id: advancedColumn
      visible: root.showAdvanced
      width: parent.width
      spacing: Style.spacing.lg

      Text {
        text: "Advanced"
        color: root.barForeground
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      PanelSeparator { foreground: root.barForeground }

      PanelSectionHeader { text: "Pointer speed range"; foreground: root.barForeground }

      Row {
        spacing: Style.spacing.lg

        FloatSpinField {
          label: "Min"
          value: root.pointerMin
          from: -1
          to: root.pointerMax - 0.05
          stepSize: 0.05
          foreground: root.barForeground
          onModified: function(v) { root.setAdvanced("pointerMin", v) }
        }

        FloatSpinField {
          label: "Max"
          value: root.pointerMax
          from: root.pointerMin + 0.05
          to: 1
          stepSize: 0.05
          foreground: root.barForeground
          onModified: function(v) { root.setAdvanced("pointerMax", v) }
        }
      }

      PanelSectionHeader { text: "Scroll speed range"; foreground: root.barForeground }

      Row {
        spacing: Style.spacing.lg

        FloatSpinField {
          label: "Min"
          value: root.scrollMin
          from: 0
          to: root.scrollMax - 0.05
          stepSize: 0.05
          foreground: root.barForeground
          onModified: function(v) { root.setAdvanced("scrollMin", v) }
        }

        FloatSpinField {
          label: "Max"
          value: root.scrollMax
          from: root.scrollMin + 0.05
          to: 2
          stepSize: 0.05
          foreground: root.barForeground
          onModified: function(v) { root.setAdvanced("scrollMax", v) }
        }
      }

      PanelSectionHeader { text: "Slider precision"; foreground: root.barForeground }

      FloatSpinField {
        label: "Step size"
        value: root.sliderStep
        from: 0.01
        to: 0.5
        stepSize: 0.01
        foreground: root.barForeground
        onModified: function(v) { root.setAdvanced("sliderStep", v) }
      }

      PanelSeparator { foreground: root.barForeground }

      Item {
        width: parent.width
        height: Math.max(resetRangesButton.implicitHeight, doneButton.implicitHeight)

        Button {
          id: resetRangesButton
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Reset ranges"
          foreground: root.barForeground
          bordered: true
          onClicked: root.resetAdvanced()
        }

        Button {
          id: doneButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "Done"
          foreground: root.barForeground
          bordered: true
          onClicked: root.showAdvanced = false
        }
      }
    }
  }
}
