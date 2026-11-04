import QtQuick
import QtQuick.Effects
import Quickshell.Services.UPower
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Bikram.js" as Bikram
import "Nepali.js" as Nepali

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property var currentDate: new Date()

  readonly property var bikramDate: Bikram.today(currentDate)
  readonly property string nepaliDateText: bikramDate
    ? Nepali.formatDate(bikramDate, { format: "Full", numerals: "Devanagari" })
    : "मिति उपलब्ध छैन"
  readonly property string englishDateText: Qt.locale("en_US").toString(currentDate, "d MMMM yyyy")
  readonly property string batteryStatusText: {
    var device = UPower.displayDevice
    if (!device || !device.isPresent) return "Battery unavailable"
    var state = device.state === UPowerDeviceState.Charging
      ? "Charging"
      : (device.state === UPowerDeviceState.FullyCharged
          ? "Fully charged"
          : (UPower.onBattery ? "On battery" : "Plugged in"))
    var percentage = Math.round(Number(device.percentage || 0) * 100)
    return "Battery  " + percentage + "%  ·  " + state
  }

  readonly property string placeholderText: "Enter Password"
  readonly property int fieldWidth: Math.round(381 * 0.6)
  readonly property int fieldHeight: Math.round(67 * 0.6)
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Commons.Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Commons.Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      id: lockContent
      anchors.centerIn: parent
      width: Math.min(parent.width - 48, 760)
      spacing: 16

      Text {
        width: parent.width
        text: root.nepaliDateText + " | " + root.englishDateText
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.heading * 0.9)
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: Qt.formatTime(root.currentDate, "h:mm AP")
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.heading * 1.7)
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: "Welcome !!! lets build something today"
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.heading * 0.85)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      BorderSurface {
        id: inputField
        width: root.fieldWidth
        height: root.fieldHeight
        anchors.horizontalCenter: parent.horizontalCenter
      color: Commons.Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: 20
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Commons.Color.lock.text
        selectionColor: Commons.Color.lock.selection
        selectedTextColor: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Commons.Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Commons.Color.lock.text : (root.failureMessage.length > 0 ? Commons.Color.lock.textError : Commons.Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Commons.Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 40
      text: root.batteryStatusText
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.heading * 0.7)
      horizontalAlignment: Text.AlignHCenter
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentDate = new Date()
  }
}
