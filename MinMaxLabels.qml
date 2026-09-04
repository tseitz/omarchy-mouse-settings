import QtQuick
import qs.Commons

// "Slower" / "Faster" caption pair under a slider, anchored to opposite
// edges so it doesn't depend on the two labels being the same width.
Item {
  id: root

  property color foreground: Color.foreground
  property string leftText: ""
  property string rightText: ""

  implicitHeight: leftLabel.implicitHeight

  Text {
    id: leftLabel
    anchors.left: parent.left
    text: root.leftText
    color: Qt.darker(root.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    anchors.right: parent.right
    text: root.rightText
    color: Qt.darker(root.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
