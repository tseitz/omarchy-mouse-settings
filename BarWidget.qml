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
    anchors.fill: parent
    bar: root.bar
    text: "\u{f037d}"
    tooltipText: "Mouse settings"
    onPressed: function(button) {
      if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
    }
  }
}
