import QtQuick
import Quickshell
import qs.Ui

// The visible bar icon. Its popup lives in Panel.qml, loaded lazily so the
// bar doesn't pay for the settings UI until someone actually opens it.
BarWidget {
  id: root
  moduleName: "io.github.tseitz.mouse-settings"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  // The base BarWidget item has no implicit size of its own — without this,
  // the bar's layout collapses this widget to 0x0 and the icon never shows.
  implicitWidth: icon.implicitWidth
  implicitHeight: icon.implicitHeight

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: icon
    anchors.fill: parent
    bar: root.bar
    text: "󰍽"
    tooltipText: "Mouse settings"
    onPressed: function(button) {
      if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
    }
  }
}
