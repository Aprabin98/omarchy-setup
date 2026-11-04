import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "prabn.system-monitor"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property var stats: ({})
  readonly property var cards: [
    {
      title: "CPU",
      value: stats.cpu_percent === undefined ? "--" : stats.cpu_percent + "%",
      percent: Number(stats.cpu_percent || 0),
      detail: (stats.cpu_model || "Processor") + " · " + (stats.cpu_threads || "--") + " threads",
      footer: "Package temperature  " + (stats.cpu_temp || "--")
    },
    {
      title: "GPU",
      value: stats.gpu_percent && stats.gpu_percent !== "unavailable" ? stats.gpu_percent : "N/A",
      percent: stats.gpu_percent && stats.gpu_percent !== "unavailable" ? Number(stats.gpu_percent.replace("%", "")) : -1,
      detail: (stats.gpu_name || "Graphics device") + " · " + (stats.gpu_frequency || "frequency N/A"),
      footer: "GPU temperature  " + (stats.gpu_temp || "unavailable")
    },
    {
      title: "MEMORY",
      value: stats.memory_percent === undefined ? "--" : stats.memory_percent + "%",
      percent: Number(stats.memory_percent || 0),
      detail: (stats.memory_used || "--") + " / " + (stats.memory_total || "--") + " used",
      footer: "Swap  " + (stats.swap_used || "--") + " / " + (stats.swap_total || "--")
    },
    {
      title: "SYSTEM",
      value: stats.disk_percent === undefined ? "--" : stats.disk_percent + "%",
      percent: Number(stats.disk_percent || 0),
      detail: "Root disk  " + (stats.disk_used || "--"),
      footer: "Battery " + (stats.battery || "--") + " · SSD " + (stats.ssd_temp || "--") + "\n" + (stats.uptime || "") + " · kernel " + (stats.kernel || "")
    }
  ]
  readonly property var accents: ["#62d8ef", "#c792ea", "#a8d76f", "#ffc66d"]
  readonly property string tooltipText: {
    if (stats.cpu_percent === undefined) return "System monitor (click to open)"
    return "CPU " + cards[0].value + " · GPU " + cards[1].value + " · RAM " + cards[2].value + " · Disk " + cards[3].value
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function parseStats(raw) {
    var next = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var separator = lines[i].indexOf("=")
      if (separator < 0) continue
      next[lines[i].slice(0, separator).trim()] = lines[i].slice(separator + 1).trim()
    }
    stats = next
  }

  onOpenedChanged: if (opened) refresh()

  Process {
    id: statsProc
    command: ["bash", Quickshell.env("HOME") + "/.config/omarchy/bar/scripts/omarchy-system-status", "--stats"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseStats(text) }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(500))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(400))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(9)

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "SYSTEM MONITOR"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            text: "LIVE · 1 SEC"
            color: Commons.Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        GridLayout {
          id: cardsGrid
          width: parent.width
          columns: 2
          columnSpacing: Style.space(8)
          rowSpacing: Style.space(8)

          Repeater {
            model: root.cards

            delegate: Rectangle {
              required property int index
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: Style.space(142)
              radius: Style.cornerRadius
              color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.035)
              border.width: 1
              border.color: root.accents[index]

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(9)
                spacing: Style.space(5)

                Text {
                  text: modelData.title
                  color: root.accents[index]
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.2
                }

                Text {
                  text: modelData.value
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.display
                  font.bold: true
                }

                Rectangle {
                  width: parent.width
                  height: Style.space(5)
                  radius: height / 2
                  color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)

                  Rectangle {
                    width: modelData.percent < 0 ? 0 : parent.width * Math.max(0, Math.min(100, modelData.percent)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.accents[index]
                  }
                }

                Text {
                  width: parent.width
                  text: modelData.detail
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.footer
                  color: Qt.darker(root.bar.foreground, 1.45)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.Wrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                }
              }
            }
          }
        }
      }
    }
  }
}
