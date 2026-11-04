//@ pragma AppId com.omarchy.OmarchyLauncher
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
  id: root

  property string configPath: Quickshell.env("XDG_CONFIG_HOME")
    ? Quickshell.env("XDG_CONFIG_HOME") + "/omarchy-launcher/config.json"
    : Quickshell.env("HOME") + "/.config/omarchy-launcher/config.json"
  property var config: ({
    pinned: [],
    radius: 238, iconSize: 44, animationMs: 110,
    mouseNavigation: true, keyboardNavigation: true,
    colors: { pink: "#b784ff", purple: "#7548bd", cyan: "#a98bff", text: "#f5efff" }
  })
  property bool configLoaded: false
  property bool settingsOpen: false
  property var settingsPinned: []
  property string query: ""
  property string settingsQuery: ""
  property int selectedApp: 0
  property int selectedWindow: 0
  property string activeRing: "apps"
  property bool closing: false
  property int screenChangeSerial: 0

  readonly property var allApps: DesktopEntries.applications.values || []
  readonly property var allWindows: Hyprland.toplevels.values || []
  readonly property var appsModel: appsForWheel()
  readonly property var windowsModel: windowsForWheel()
  onAppsModelChanged: {
    if (selectedApp >= appsModel.length) selectedApp = Math.max(0, appsModel.length - 1)
  }
  onWindowsModelChanged: {
    if (selectedWindow >= windowsModel.length) selectedWindow = Math.max(0, windowsModel.length - 1)
  }
  readonly property var colors: config.colors || ({})
  readonly property var focusedScreen: {
    const screens = Quickshell.screens
    const focused = Hyprland.focusedMonitor
    if (focused) {
      for (let i = 0; i < screens.length; i++) {
        if (Hyprland.monitorFor(screens[i]) === focused) return screens[i]
      }
    }
    return screens.length ? screens[0] : null
  }

  function appName(app) { return String(app.name || app.id || "") }
  function appKey(app) { return String(app.id || "").replace(/\.desktop$/i, "") }
  function appSearchText(app) {
    return [app.name, app.genericName, app.comment, app.id,
            app.keywords ? app.keywords.join(" ") : "", app.command ? app.command.join(" ") : ""]
      .join(" ").toLocaleLowerCase()
  }
  function sortedApps() {
    return Array.from(allApps).filter(function(app) {
      return app && !app.noDisplay && appName(app).length > 0 && app.command && app.command.length > 0
    }).sort(function(a, b) { return appName(a).localeCompare(appName(b)) })
  }
  function appsForWheel() {
    const apps = sortedApps()
    if (query.trim().length) {
      const terms = query.toLocaleLowerCase().trim().split(/\s+/)
      return apps.filter(function(app) {
        const text = appSearchText(app)
        return terms.every(function(term) { return text.indexOf(term) >= 0 })
      })
    }
    const pins = config.pinned || []
    const ordered = []
    for (let i = 0; i < pins.length; i++) {
      const app = apps.find(function(candidate) { return appKey(candidate) === pins[i] })
      if (app) ordered.push(app)
    }
    return ordered.length ? ordered : apps.slice(0, 10)
  }
  function windowAppId(win) { return String(win && win.wayland ? win.wayland.appId : "") }
  function windowTitle(win) { return String(win && (win.title || (win.wayland && win.wayland.title)) || "Untitled window") }
  function windowWorkspace(win) {
    return win && win.workspace ? String(win.workspace.name || win.workspace.id) : "?"
  }
  function windowsForWheel() {
    const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    return Array.from(allWindows).filter(function(win) {
      if (!win || !win.wayland || !windowTitle(win).length) return false
      const ownId = windowAppId(win).toLocaleLowerCase()
      if (ownId.indexOf("omarchylauncher") >= 0 || windowTitle(win) === "Omarchy Launcher") return false
      if (query.trim().length) {
        const text = (windowTitle(win) + " " + windowAppId(win) + " " + windowWorkspace(win)).toLocaleLowerCase()
        const terms = query.toLocaleLowerCase().trim().split(/\s+/)
        return terms.every(function(term) { return text.indexOf(term) >= 0 })
      }
      return true
    }).sort(function(a, b) {
      const aRank = a.workspace && a.workspace.id === focusedId ? 0 : 1
      const bRank = b.workspace && b.workspace.id === focusedId ? 0 : 1
      if (aRank !== bRank) return aRank - bRank
      const aWs = a.workspace ? a.workspace.id : 9999
      const bWs = b.workspace ? b.workspace.id : 9999
      if (aWs !== bWs) return aWs - bWs
      return windowTitle(a).localeCompare(windowTitle(b))
    })
  }
  function currentApps() { return appsModel }
  function currentWindows() { return windowsModel }
  function setInitialRing() {
    selectedApp = 0
    selectedWindow = 0
    activeRing = !query.trim().length || currentApps().length ? "apps" : "windows"
  }
  function readConfig(text) {
    try {
      const value = JSON.parse(text)
      if (value && typeof value === "object") {
        if (Array.isArray(value.pinned)) value.pinned = value.pinned.map(function(id) { return String(id).replace(/\.desktop$/i, "") })
        config = Object.assign({}, config, value)
      }
    } catch (error) {
      console.warn("Omarchy Launcher: config could not be parsed:", error)
    }
    configLoaded = true
  }
  function saveConfig() {
    configFile.setText(JSON.stringify(config, null, 2) + "\n")
  }
  function openSettings() {
    settingsPinned = Array.from(config.pinned || [])
    settingsQuery = ""
    settingsSearch.text = ""
    settingsOpen = true
    overlay.visible = false
    settingsWindow.visible = true
    Qt.callLater(function() { settingsSearch.forceActiveFocus() })
  }
  function cancelSettings() {
    settingsOpen = false
    settingsWindow.visible = false
    overlay.visible = true
    Qt.callLater(function() { keyFocus.forceActiveFocus() })
  }
  function openLauncher() {
    closing = false
    query = ""
    settingsOpen = false
    settingsWindow.visible = false
    setInitialRing()
    overlay.visible = true
    keyFocus.opacity = 0
    Qt.callLater(function() {
      keyFocus.forceActiveFocus()
      keyFocus.opacity = 1
    })
  }
  function closeLauncher() {
    if (!overlay.visible || closing) return
    closing = true
    keyFocus.opacity = 0
    closeDelay.restart()
  }
  function toggleLauncher() {
    if (overlay.visible) closeLauncher()
    else openLauncher()
  }
  function launchApp(app) {
    if (!app) return
    let id = appKey(app)
    if (id.slice(-8) !== ".desktop") id += ".desktop"
    Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", id])
    closeLauncher()
  }
  function activateWindow(win) {
    if (!win || !win.wayland) return
    win.wayland.activate()
    closeLauncher()
  }
  function clearOrClose() {
    if (settingsOpen) cancelSettings()
    else if (query.length) { query = ""; setInitialRing() }
    else closeLauncher()
  }
  function cycleSelection(direction) {
    if (activeRing === "windows" && currentWindows().length) {
      selectedWindow = (selectedWindow + direction + currentWindows().length) % currentWindows().length
    } else if (currentApps().length) {
      activeRing = "apps"
      selectedApp = (selectedApp + direction + currentApps().length) % currentApps().length
    }
  }
  function selectedEntry() {
    if (activeRing === "windows") return currentWindows()[selectedWindow] || null
    return currentApps()[selectedApp] || null
  }
  function submitSelection() {
    if (activeRing === "windows") activateWindow(selectedEntry())
    else launchApp(selectedEntry())
  }
  function selectAt(x, y, force) {
    if ((!config.mouseNavigation && !force) || settingsOpen) return false
    const cx = overlay.width / 2, cy = overlay.height / 2
    const dx = x - cx, dy = y - cy
    const distance = Math.sqrt(dx * dx + dy * dy)
    const outer = Math.min(Number(config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38)
    const appInner = outer * 0.64
    const winOuter = appInner - Math.max(7, outer * 0.035)
    const winInner = outer * 0.22
    let items = []
    if (distance >= winInner && distance <= winOuter) {
      items = currentWindows()
      if (!items.length) return false
      activeRing = "windows"
    } else if (distance >= appInner && distance <= outer + 10) {
      items = currentApps()
      if (!items.length) return false
      activeRing = "apps"
    } else return false
    const angle = (Math.atan2(dy, dx) + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2)
    const index = Math.round(angle * items.length / (Math.PI * 2)) % items.length
    if (activeRing === "windows") selectedWindow = index
    else selectedApp = index
    return true
  }
  function iconForApp(app) {
    const icon = String(app && app.icon || "application-x-executable")
    if (icon.indexOf("/") === 0) return "file://" + icon
    if (icon.indexOf("file:") === 0 || icon.indexOf("image:") === 0) return icon
    return Quickshell.iconPath(icon, true) || Quickshell.iconPath("application-x-executable")
  }
  function iconForWindow(win) {
    const appId = windowAppId(win).toLocaleLowerCase()
    const app = allApps.find(function(item) {
      const key = appKey(item).toLocaleLowerCase().replace(/\.desktop$/, "")
      const startup = String(item.startupClass || "").toLocaleLowerCase()
      return (key && (appId === key || appId.indexOf(key) >= 0)) || (startup && appId === startup)
    })
    return app ? iconForApp(app) : Quickshell.iconPath("application-x-executable")
  }
  function savePinnedApps() {
    config = Object.assign({}, config, { pinned: Array.from(settingsPinned) })
    saveConfig()
    settingsOpen = false
    settingsWindow.visible = false
    overlay.visible = true
    setInitialRing()
    Qt.callLater(function() { keyFocus.forceActiveFocus() })
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.readConfig(text())
    onLoadFailed: {
      root.configLoaded = true
      root.saveConfig()
    }
    onFileChanged: reload()
  }

  IpcHandler {
    target: "omarchy-launcher"
    function toggle(): string { root.toggleLauncher(); return "ok" }
    function show(): string { root.openLauncher(); return overlay.visible ? "visible" : "hidden" }
    function hide(): string { root.closeLauncher(); return "ok" }
    function ping(): string { return "ok" }
    function status(): string {
      return JSON.stringify({ visible: overlay.visible, query: root.query,
        apps: root.currentApps().length, windows: root.currentWindows().length,
        activeRing: root.activeRing,
        selected: root.activeRing === "windows" ? root.selectedWindow : root.selectedApp })
    }
  }

  Timer {
    id: closeDelay
    interval: Number(root.config.animationMs) || 110
    onTriggered: {
      overlay.visible = false
      root.closing = false
    }
  }

  PanelWindow {
    id: overlay
    screen: root.focusedScreen
    visible: false
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "omarchy-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    surfaceFormat.opaque: false

    Item {
      id: keyFocus
      anchors.fill: parent
      focus: true
      opacity: 1
      Behavior on opacity { NumberAnimation { duration: Number(root.config.animationMs) || 110; easing.type: Easing.OutCubic } }
      Keys.onPressed: function(event) {
        if (!root.config.keyboardNavigation && !root.settingsOpen) return
        if (event.key === Qt.Key_Escape) {
          root.clearOrClose()
          event.accepted = true
          return
        }
        if (root.settingsOpen) return
        if (event.key === Qt.Key_Backspace && root.query.length) {
          root.query = root.query.slice(0, -1)
          root.setInitialRing()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
          root.activeRing = root.activeRing === "apps" && root.currentWindows().length ? "windows" : "apps"
          event.accepted = true
        } else if ((event.key === Qt.Key_Space) && root.query.length) {
          root.query += " "
          root.setInitialRing()
          event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
          root.cycleSelection(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
          root.cycleSelection(1)
          event.accepted = true
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 || event.key === Qt.Key_0) {
          const index = event.key === Qt.Key_0 ? 9 : event.key - Qt.Key_1
          if (root.activeRing === "windows" && index < root.currentWindows().length) root.selectedWindow = index
          else if (root.activeRing === "apps" && index < root.currentApps().length) root.selectedApp = index
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          root.submitSelection()
          event.accepted = true
        } else if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && event.text.length) {
          const character = event.text
          if (character.trim().length || character === " ") {
            root.query += character
            root.selectedApp = 0
            root.selectedWindow = 0
            root.activeRing = root.currentApps().length ? "apps" : "windows"
            event.accepted = true
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPositionChanged: function(mouse) { root.selectAt(mouse.x, mouse.y) }
        onClicked: function(mouse) {
          const outer = Math.min(Number(root.config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38)
          const distance = Math.hypot(mouse.x - overlay.width / 2, mouse.y - overlay.height / 2)
          if (distance > outer + 16) root.closeLauncher()
          else {
            if (root.selectAt(mouse.x, mouse.y, true)) root.submitSelection()
          }
        }
      }

      Canvas {
        id: wheel
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        property string refreshToken: root.query + ":" + root.activeRing + ":" + root.selectedApp + ":" + root.selectedWindow + ":" + root.currentApps().length + ":" + root.currentWindows().length
        onRefreshTokenChanged: requestPaint()
        Component.onCompleted: requestPaint()
        function drawRing(ctx, count, inner, outer, index, accent, enabled) {
          if (!count) return
          const slots = count
          const step = Math.PI * 2 / slots
          const gap = Math.min(0.075, step * 0.15)
          for (let i = 0; i < count; i++) {
            const angle = -Math.PI / 2 + Math.PI * 2 * i / count
            const start = angle - step / 2 + gap
            const end = angle + step / 2 - gap
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, outer, start, end)
            ctx.lineTo(width / 2 + Math.cos(end) * inner, height / 2 + Math.sin(end) * inner)
            ctx.arc(width / 2, height / 2, inner, end, start, true)
            ctx.closePath()
            const selected = enabled && i === index
            const fill = ctx.createLinearGradient(width / 2, height / 2 - inner, width / 2, height / 2 - outer)
            fill.addColorStop(0, selected ? "rgba(48, 48, 57, 0.97)" : "rgba(24, 27, 34, 0.92)")
            fill.addColorStop(1, selected ? "rgba(37, 39, 47, 0.98)" : "rgba(18, 21, 28, 0.94)")
            ctx.fillStyle = fill
            ctx.fill()
            ctx.strokeStyle = selected ? accent : "rgba(235, 232, 225, 0.14)"
            ctx.lineWidth = selected ? 1.8 : 0.8
            ctx.stroke()
            if (selected) {
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, outer - 1, start, end)
              ctx.strokeStyle = accent
              ctx.globalAlpha = 0.55
              ctx.lineWidth = 2.8
              ctx.stroke()
              ctx.globalAlpha = 1
            }
          }
        }
        onPaint: {
          const ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          const cx = width / 2, cy = height / 2
          const outer = Math.min(Number(root.config.radius) || 238, Math.min(width, height) * 0.38)
          const appInner = outer * 0.64
          const winOuter = appInner - Math.max(7, outer * 0.035)
          const winInner = outer * 0.22
          drawRing(ctx, root.currentWindows().length, winInner, winOuter, root.selectedWindow, root.colors.purple || "#975cff", root.activeRing === "windows")
          drawRing(ctx, root.currentApps().length, appInner, outer, root.selectedApp, root.colors.purple || "#975cff", root.activeRing === "apps")
          ctx.beginPath(); ctx.arc(cx, cy, winInner - 6, 0, Math.PI * 2)
          const centerFill = ctx.createRadialGradient(cx - 20, cy - 24, 2, cx, cy, winInner)
          centerFill.addColorStop(0, "rgba(49, 51, 59, 0.99)")
          centerFill.addColorStop(1, "rgba(23, 26, 33, 0.99)")
          ctx.fillStyle = centerFill; ctx.fill()
          ctx.strokeStyle = "rgba(235, 232, 225, 0.24)"; ctx.lineWidth = 1; ctx.stroke()
          ctx.beginPath(); ctx.arc(cx, cy, outer + 9, 0, Math.PI * 2)
          ctx.strokeStyle = "rgba(235, 232, 225, 0.2)"; ctx.lineWidth = 1; ctx.stroke()
        }
      }

      Repeater {
        model: root.currentWindows()
        delegate: Item {
          required property int index
          required property var modelData
          readonly property real size: Math.min(Number(root.config.iconSize) * 0.84, Math.max(14, ((ringOuter - inner) / 2) * Math.PI * 2 / Math.max(6, root.currentWindows().length) * 0.56))
          readonly property real outer: Math.min(Number(root.config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38)
          readonly property real inner: outer * 0.22
          readonly property real ringOuter: outer * 0.64 - Math.max(7, outer * 0.035)
          readonly property real angle: -Math.PI / 2 + Math.PI * 2 * index / Math.max(1, root.currentWindows().length)
          readonly property real mid: (inner + ringOuter) / 2 - 7
          x: overlay.width / 2 + Math.cos(angle) * mid - size / 2
          y: overlay.height / 2 + Math.sin(angle) * mid - size / 2
          width: size
          height: size + 22
          opacity: root.activeRing === "windows" && index === root.selectedWindow ? 1 : 0.88
          Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.size * (root.activeRing === "windows" && parent.index === root.selectedWindow ? 1.14 : 0.92)
            height: width
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Rectangle { anchors.fill: parent; anchors.margins: -5; radius: width; color: "rgba(240, 238, 232, 0.09)"; border.color: "rgba(240, 238, 232, 0.16)"; border.width: 1; z: -1 }
            source: root.iconForWindow(parent.modelData)
            sourceSize.width: 96
            sourceSize.height: 96
            fillMode: Image.PreserveAspectFit
            smooth: true
          }
          Text {
            anchors.top: parent.top
            anchors.topMargin: parent.size + 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(46, Math.min(94, parent.size * 2.2))
            horizontalAlignment: Text.AlignHCenter
            text: root.windowTitle(parent.modelData) + " · WS" + root.windowWorkspace(parent.modelData)
            color: root.colors.text || "#f4f1ed"
            font.pixelSize: root.activeRing === "windows" && parent.index === root.selectedWindow ? 10 : 9
            font.bold: parent.index === root.selectedWindow
            elide: Text.ElideRight
          }
        }
      }

      Repeater {
        model: root.currentApps()
        delegate: Item {
          required property int index
          required property var modelData
          readonly property real size: Math.min(Number(root.config.iconSize) || 44, Math.max(14, ((outer - inner) / 2) * Math.PI * 2 / Math.max(6, root.currentApps().length) * 0.56))
          readonly property real outer: Math.min(Number(root.config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38)
          readonly property real inner: outer * 0.64
          readonly property real angle: -Math.PI / 2 + Math.PI * 2 * index / Math.max(1, root.currentApps().length)
          readonly property real mid: (inner + outer) / 2 - 7
          x: overlay.width / 2 + Math.cos(angle) * mid - size / 2
          y: overlay.height / 2 + Math.sin(angle) * mid - size / 2
          width: size
          height: size + 22
          Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.size * (root.activeRing === "apps" && parent.index === root.selectedApp ? 1.14 : 0.92)
            height: width
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Rectangle { anchors.fill: parent; anchors.margins: -5; radius: width; color: "rgba(240, 238, 232, 0.09)"; border.color: "rgba(240, 238, 232, 0.16)"; border.width: 1; z: -1 }
            source: root.iconForApp(parent.modelData)
            sourceSize.width: 96
            sourceSize.height: 96
            fillMode: Image.PreserveAspectFit
            smooth: true
          }
          Text {
            anchors.top: parent.top
            anchors.topMargin: parent.size + 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(46, Math.min(94, parent.size * 2.2))
            horizontalAlignment: Text.AlignHCenter
            text: root.appName(parent.modelData)
            color: root.colors.text || "#f4f1ed"
            font.pixelSize: root.activeRing === "apps" && parent.index === root.selectedApp ? 10 : 9
            font.bold: parent.index === root.selectedApp
            elide: Text.ElideRight
          }
        }
      }

      Rectangle {
        id: centerCard
        anchors.centerIn: parent
        width: Math.max(124, Math.min(Number(root.config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38) * 0.58)
        height: width
        radius: width / 2
        color: "#e5161022"
        border.color: "#62408e"
        border.width: 1
        Column {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 3
          Text {
            width: parent.width
            text: root.activeRing === "windows" ? "OPEN WINDOW" : "APPLICATION"
            color: root.colors.purple || "#975cff"
            font.pixelSize: 8
            font.letterSpacing: 1.4
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            width: parent.width
            text: {
              const entry = root.selectedEntry()
              if (!entry) return root.query.length ? "No matches" : "Choose an item"
              return root.activeRing === "windows" ? root.windowTitle(entry) : root.appName(entry)
            }
            color: root.colors.text || "#f5efff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
          }
          Text {
            width: parent.width
            text: root.activeRing === "windows" && root.selectedEntry()
              ? "Workspace " + root.windowWorkspace(root.selectedEntry())
              : root.query.length ? "Search · " + root.query : "↑ ↓  Select   ·   Enter  Open"
            color: "#c0b3d4"
            font.pixelSize: 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.activeRing === "windows" ? "Tab  Apps   ·   Esc  Close" : "Tab  Windows   ·   Esc  Close"
            color: "#9585aa"
            font.pixelSize: 8
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      Rectangle {
        id: settingsButton
        z: 5
        readonly property real wheelRadius: Math.min(Number(root.config.radius) || 238, Math.min(overlay.width, overlay.height) * 0.38)
        x: overlay.width / 2 - width / 2
        y: Math.max(12, overlay.height / 2 - wheelRadius - 44)
        width: 48
        height: 48
        radius: 24
        color: "#211a2d"
        border.color: root.colors.purple || "#7548bd"
        border.width: 1
        Text { anchors.centerIn: parent; text: "⚙"; color: root.colors.text || "#f4f1ed"; font.pixelSize: 21 }
        MouseArea { anchors.fill: parent; onClicked: root.openSettings() }
      }
    }
  }

  PanelWindow {
    id: settingsWindow
    screen: root.focusedScreen
    visible: false
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "omarchy-launcher-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    surfaceFormat.opaque: false

    Item {
      anchors.fill: parent
      Rectangle {
        anchors.fill: parent
        color: "#55070812"
        MouseArea { anchors.fill: parent; onClicked: root.cancelSettings() }
      }
      Rectangle {
        id: settingsCard
        z: 1
        anchors.centerIn: parent
        width: Math.min(parent.width - 36, 640)
        height: Math.min(parent.height - 36, 680)
        radius: 22
        color: "#f2141020"
        border.color: "#6841a3"
        border.width: 1
        MouseArea { anchors.fill: parent; onClicked: mouse.accepted = true }
        Column {
          z: 1
          anchors.fill: parent
          anchors.margins: 22
          spacing: 10
          Row {
            width: parent.width
            spacing: 12
            Rectangle {
              width: 42; height: 42; radius: 13
              color: "#33234b"
              border.color: "#7650b2"
              Text { anchors.centerIn: parent; text: "⚙"; color: "#d5b8ff"; font.pixelSize: 21 }
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              Text { text: "Pinned applications"; color: root.colors.text || "#f5efff"; font.pixelSize: 20; font.bold: true }
              Text { text: "Choose the apps shown around the outer ring."; color: "#aaa2b8"; font.pixelSize: 12 }
            }
          }
          Rectangle {
            width: parent.width; height: 44; radius: 11
            color: "#211a2e"
            border.color: settingsSearch.activeFocus ? "#a978f2" : "#49365f"
            TextInput {
              id: settingsSearch
              anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
              color: root.colors.text || "#f5efff"
              font.pixelSize: 13
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              onTextChanged: root.settingsQuery = text
              Keys.onEscapePressed: root.cancelSettings()
              Text { anchors.fill: parent; visible: !settingsSearch.text.length; text: "Search installed applications…"; color: "#81778f"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            }
          }
          Flickable {
            id: appList
            width: parent.width
            height: Math.max(72, parent.height - 164)
            contentHeight: appRows.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
              id: appRows
              width: appList.width
              spacing: 6
              Repeater {
                model: root.sortedApps().filter(function(app) {
                  return !root.settingsQuery.length || root.appSearchText(app).indexOf(root.settingsQuery.toLocaleLowerCase()) >= 0
                })
                delegate: Rectangle {
                  required property var modelData
                  width: appRows.width; height: 48; radius: 10
                  readonly property bool chosen: root.settingsPinned.indexOf(root.appKey(modelData)) >= 0
                  color: chosen ? "#332342" : rowMouse.containsMouse ? "#292134" : "#201a2b"
                  border.color: chosen ? "#8d5bd0" : "#392e49"
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Row {
                    anchors.fill: parent; anchors.leftMargin: 11; anchors.rightMargin: 11; spacing: 11
                    Image { anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30; source: root.iconForApp(parent.parent.modelData); sourceSize.width: 64; sourceSize.height: 64; fillMode: Image.PreserveAspectFit; smooth: true }
                    Text { width: parent.width - 88; height: parent.height; verticalAlignment: Text.AlignVCenter; text: root.appName(parent.parent.modelData); color: root.colors.text || "#f5efff"; font.pixelSize: 13; elide: Text.ElideRight }
                    Rectangle {
                      anchors.verticalCenter: parent.verticalCenter
                      width: 27; height: 27; radius: 9
                      color: parent.parent.chosen ? "#7646ad" : "#30263c"
                      border.color: parent.parent.chosen ? "#b88cff" : "#544265"
                      Text { anchors.centerIn: parent; text: parent.parent.parent.chosen ? "✓" : "+"; color: "#f7f0ff"; font.pixelSize: 16; font.bold: true }
                    }
                  }
                  MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                      let pins = Array.from(root.settingsPinned)
                      const index = pins.indexOf(root.appKey(parent.modelData))
                      if (index >= 0) pins.splice(index, 1)
                      else pins.push(root.appKey(parent.modelData))
                      root.settingsPinned = pins
                    }
                  }
                }
              }
            }
          }
          Row {
            width: parent.width
            spacing: 9
            Text {
              width: parent.width - 202
              height: 40
              verticalAlignment: Text.AlignVCenter
              text: root.settingsPinned.length + " applications selected"
              color: "#bca3df"
              font.pixelSize: 12
              elide: Text.ElideRight
            }
            Rectangle {
              width: 94; height: 40; radius: 11
              color: "#8151bf"
              border.color: "#ad7be8"
              Text { anchors.centerIn: parent; text: "Save"; color: "#fffaff"; font.pixelSize: 13; font.bold: true }
              MouseArea { anchors.fill: parent; onClicked: root.savePinnedApps() }
            }
            Rectangle {
              width: 90; height: 40; radius: 11
              color: "#292233"
              border.color: "#51415f"
              Text { anchors.centerIn: parent; text: "Cancel"; color: "#d5cedf"; font.pixelSize: 13; font.bold: true }
              MouseArea { anchors.fill: parent; onClicked: root.cancelSettings() }
            }
          }
        }
      }
    }
  }
}
