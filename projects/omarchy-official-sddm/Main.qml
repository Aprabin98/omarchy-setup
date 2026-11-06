import QtQuick 2.0
import QtQuick.Effects
import SddmComponents 2.0
import "Bikram.js" as Bikram
import "Nepali.js" as Nepali

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1a1b26"

    property string currentUser: userModel.lastUser
    property bool loginFailed: false
    property bool authenticating: false
    property int sessionIndex: {
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
            if (name.indexOf("uwsm") !== -1)
                return i
        }
        return sessionModel.lastIndex
    }
    property var now: new Date()

    readonly property var bikramDate: Bikram.today(now)
    readonly property string nepaliDateText: bikramDate
        ? Nepali.formatDate(bikramDate, { format: "Full", numerals: "Devanagari" })
        : "मिति उपलब्ध छैन"
    readonly property string englishDateText: Qt.locale("en_US").toString(now, "d MMMM yyyy")

    readonly property int fieldWidth: 229
    readonly property int fieldHeight: 40
    readonly property int dotFontSize: 25
    readonly property int dotSpacing: 4
    // Shrink dots so long passwords always stay visible inside the field
    readonly property real dotScale: dotMetrics.advanceWidth > 0
        ? Math.min(1, (password.width - 4) / dotMetrics.advanceWidth)
        : 1

    TextMetrics {
        id: dotMetrics
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.dotFontSize
        font.letterSpacing: root.dotSpacing
        text: "●".repeat(password.text.length)
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        blurEnabled: true
        blur: 1.0
        blurMax: 128
        blurMultiplier: 1.25
        contrast: -0.08
    }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false
            root.loginFailed = true
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.loginFailed = false
        }
    }

    Column {
        id: lockContent
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 760)
        spacing: 16

        Text {
            width: parent.width
            text: root.nepaliDateText + " | " + root.englishDateText
            color: "#f2f2f2"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: Qt.formatTime(root.now, "h:mm AP")
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 76
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: "Welcome !!! lets build something today"
            color: "#f2f2f2"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Rectangle {
            width: root.fieldWidth
            height: root.fieldHeight
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 20
            color: "#cc1a1b26"
            border.width: 3
            border.color: root.loginFailed ? "#f7768e" : "#7aa2f7"
            clip: true

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                clip: true
                enabled: !root.authenticating
                color: "#f2f2f2"
                selectionColor: "#7aa2f7"
                selectedTextColor: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: text.length > 0
                    ? Math.max(1, Math.floor(root.dotFontSize * root.dotScale)) : 17
                font.letterSpacing: text.length > 0 ? root.dotSpacing * root.dotScale : 0
                focus: true

                onTextChanged: if (text.length > 0) root.loginFailed = false

                function submit() {
                    if (text.length === 0) return
                    root.authenticating = true
                    sddm.login(root.currentUser, text, root.sessionIndex)
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        submit()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape
                               || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U)) {
                        password.text = ""
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                text: root.authenticating ? "Checking…"
                    : (root.loginFailed ? "Authentication failed" : "Enter Password")
                visible: password.text.length === 0
                color: root.loginFailed ? "#f7768e"
                    : (root.authenticating ? "#f2f2f2" : "#b7b9c7")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 17
                font.italic: root.loginFailed
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: password.forceActiveFocus()
}
