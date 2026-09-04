import QtQuick
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui

// NumberField.qml, but for real-valued settings (Hyprland's sensitivity and
// scroll_factor are floats). QtQuick.Controls.SpinBox only speaks integers,
// so this keeps the underlying SpinBox in hundredths and converts at the
// display/parse boundary.
Column {
  id: root

  property string label: ""
  property real value: 0
  property real from: 0
  property real to: 100
  property real stepSize: 0.05
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real fieldWidth: Style.spacing.numberFieldWidth
  property bool hasCursor: false
  property bool _hovered: false

  signal modified(real value)
  signal hovered(bool on)

  spacing: Style.spacing.md

  Text {
    textFormat: Text.PlainText
    visible: root.label !== ""
    text: root.label
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  QQC.SpinBox {
    id: spin
    width: root.fieldWidth
    implicitHeight: Math.max(Style.spacing.controlHeight, root.fontSize + Style.spacing.controlPaddingY * 2)
    from: Math.round(root.from * 100)
    to: Math.round(root.to * 100)
    stepSize: Math.max(1, Math.round(root.stepSize * 100))
    value: Math.round(root.value * 100)
    editable: true
    font.family: root.fontFamily
    font.pixelSize: root.fontSize

    textFromValue: function(value) { return (value / 100).toFixed(2) }
    valueFromText: function(text) { return Math.round(parseFloat(text) * 100) }

    readonly property bool _focused: spin.activeFocus
    readonly property bool _hot: root._hovered || root.hasCursor
    readonly property var _borderSpec: Border.controlSpec(_focused ? "focus" : (_hot ? "hover-cursor" : "normal"), root.foreground, root.accent)

    leftPadding: Border.left(_borderSpec) + Style.spacing.controlPaddingX
    rightPadding: Border.right(_borderSpec) + Style.spacing.controlPaddingX
    topPadding: Border.top(_borderSpec)
    bottomPadding: Border.bottom(_borderSpec)

    onValueModified: root.modified(value / 100)

    background: BorderSurface {
      color: Style.controlFill(spin._focused, spin._hot, root.foreground, root.accent)
      borderSpec: spin._borderSpec
      radius: Style.cornerRadius

      HoverHandler {
        onHoveredChanged: {
          root._hovered = hovered
          root.hovered(hovered)
        }
      }
    }

    contentItem: TextInput {
      text: spin.displayText
      font: spin.font
      color: root.foreground
      selectionColor: Style.selectionFillFor(root.foreground, root.accent)
      selectedTextColor: root.foreground
      horizontalAlignment: Qt.AlignHCenter
      verticalAlignment: Qt.AlignVCenter
      readOnly: !spin.editable
      validator: spin.validator
      inputMethodHints: Qt.ImhFormattedNumbersOnly
    }
  }
}
