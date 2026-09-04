import QtQuick
import qs.Commons
import qs.Ui

// PanelActionButton, but with its icon glyph optically centered. Measured
// via fontTools against JetBrainsMono Nerd Font: the cog/gear glyphs (Material
// Design cog, cog-outline, Font Awesome gear) all draw their ink about 10.6%
// of the advance width right of center. PanelActionButton's plain
// `anchors.centerIn` centers the text box, not the ink, so the icon reads as
// pushed toward the top-right corner of its square. This shifts it back.
BorderSurface {
  id: root

  property string iconText: ""
  property string tooltipText: ""
  property color foreground: Color.foreground
  property color hoverColor: foreground
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.icon
  property real size: Math.max(Style.space(22), fontSize + Style.spacing.sm * 2)
  readonly property real glyphOffsetX: -0.106 * fontSize

  signal clicked()
  signal hovered(bool isHovered)

  implicitWidth: size
  implicitHeight: size
  radius: Style.cornerRadius

  readonly property bool _hot: mouse.containsMouse && root.enabled
  readonly property var _borderSpec: _hot
    ? Border.controlSpec("hover-cursor", hoverColor, hoverColor)
    : Border.controlSpec("normal", foreground, Color.accent)

  color: _hot ? Style.hoverFillFor(hoverColor, hoverColor) : "transparent"
  borderSpec: _borderSpec

  Behavior on color { ColorAnimation { duration: 60 } }

  Text {
    textFormat: Text.PlainText
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: root.glyphOffsetX
    text: root.iconText
    color: root.enabled ? (root._hot ? root.hoverColor : root.foreground) : Qt.darker(root.foreground, 2.0)
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    enabled: root.enabled
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: root.clicked()
  }

  PanelToolTip {
    visible: root.tooltipText !== "" && mouse.containsMouse
    text: root.tooltipText
    fontFamily: root.fontFamily
  }
}
