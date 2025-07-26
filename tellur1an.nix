{ config, pkgs, ... }:

{
  home.username = "tellur1an";
  home.homeDirectory = "/home/tellur1an";
  home.stateVersion = "25.05";

  # GNOME extension settings
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        blur-my-shell.extensionUuid
        dash-to-panel.extensionUuid
        compiz-windows-effect.extensionUuid
        coverflow-alt-tab.extensionUuid
        tray-icons-reloaded.extensionUuid
        just-perfection.extensionUuid
        arcmenu.extensionUuid
        appindicator.extensionUuid
        clipboard-indicator.extensionUuid
        custom-osd.extensionUuid
        pop-shell.extensionUuid
        tiling-shell.extensionUuid
        paperwm.extensionUuid
      ];
    };
  };

  # User-specific environment variables
  home.sessionVariables = {
    TERM = "foot";
    TERMINAL = "foot";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    MOZ_DBUS_REMOTE = "1";
    GDK_BACKEND = "wayland";
    EGL_PLATFORM = "wayland";
  };

  # User-specific systemd services
  systemd.user.services.swww-daemon = {
    description = "swww wallpaper daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "always";
    };
  };

  systemd.user.services.swww-random = {
    description = "swww random wallpaper";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${config.home.homeDirectory}/swww-random.sh";
      Restart = "always";
    };
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # swww-random script
  home.file."swww-random.sh" = {
    text = ''
      #!/bin/sh
      WALLPAPER_DIR="${config.home.homeDirectory}/Pictures/Wallpapers"
      INTERVAL=300
      while true; do
        WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
        ${pkgs.swww}/bin/swww img "$WALLPAPER"
        sleep $INTERVAL
      done
    '';
    executable = true;
  };

  # Niri scripts (commented out, enable if needed for PikaOS compatibility)
  # home.file.".config/niri/launchwelcome.sh" = {
  #   text = ''
  #     #!/bin/sh
  #     ! test -e /home/pikaos && pika-welcome-autostart
  #   '';
  #   executable = true;
  # };
  # home.file.".config/niri/launchfirstrun.sh" = {
  #   text = ''
  #     #!/bin/sh
  #     ! test -e /live/filesystem.squashfs && test -e /home/pikaos && pika-first-setup-gtk4
  #   '';
  #   executable = true;
  # };
  # home.file.".config/niri/launchinstall.sh" = {
  #   text = ''
  #     #!/bin/sh
  #     test -e /live/filesystem.squashfs && pika-installer
  #   '';
  #   executable = true;
  # };

  # Quickshell configuration
  home.file.".config/quickshell/bar.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Widgets
    import "widgets" as Widgets

    PanelWindow {
        id: panel
        property var weatherConfig: ({ isamerican: true, city: "Bentonville", weatherupdateinterval: 900 })
        property var clockConfig: ({ twelvehourclock: false, reversedaymonth: false })
        property string sysInfoInterval: "2s"
        property int workspaces: 10
        property bool isNiri: Quickshell.env("XDG_CURRENT_DESKTOP") === "niri"

        anchors {
            top: true
            left: true
            right: true
        }

        height: 40
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#4a0138"

            RowLayout {
                spacing: 12
                width: parent.width
                height: parent.height
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: parent.width
                implicitHeight: parent.height

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        spacing: 12
                        anchors.fill: parent
                        anchors.leftMargin: 10

                        Widgets.Workspaces {
                            id: workspacesWidget
                            visible: !panel.isNiri
                            anchors.verticalCenter: parent.verticalCenter
                            workspaces: panel.workspaces
                            implicitHeight: panel.height
                            Layout.preferredWidth: implicitWidth
                        }

                        Widgets.Stats {
                            id: statsWidgetNiri
                            visible: panel.isNiri
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.preferredWidth: 120
                            updateInterval: panel.sysInfoInterval
                        }

                        Widgets.Weather {
                            id: weatherWidget
                            city: panel.weatherConfig.city
                            isAmerican: panel.weatherConfig.isamerican
                            updateInterval: panel.weatherConfig.weatherupdateinterval
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: panel.height
                        }

                        Widgets.NowPlaying {
                            id: nowPlayingWidget
                            Layout.fillWidth: true
                            Layout.maximumWidth: panel.isNiri ? (panel.width / 3) : (panel.width / 4)
                            Layout.preferredHeight: panel.height
                            Layout.leftMargin: 10
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Widgets.ActiveWindow {
                            Layout.fillWidth: true
                            Layout.preferredHeight: panel.height
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors {
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            rightMargin: 10
                        }
                        spacing: 8

                        Widgets.Stats {
                            visible: !panel.isNiri
                            updateInterval: panel.sysInfoInterval
                            Layout.preferredWidth: 120
                        }
                        Widgets.Power {}
                        Widgets.SystemTray {}
                        Widgets.Clock {
                            twelveHourClock: panel.clockConfig.twelvehourclock ?? false
                            reverseDayMonth: panel.clockConfig.reversedaymonth ?? false
                        }
                    }
                }
            }
        }
    }
  '';

  home.file.".config/quickshell/CommonStyles.qml".text = ''
    import QtQuick

    QtObject {
        id: root
        property string tooltipBackground: "#5d0140"
        property string tooltipTextColor: "white"
        property string textColor: "white"
        property string fontFamily: "Ubuntu"
        property string fontFamilySans: "Sans"
        property string iconFontFamily: "Material Symbols Rounded"
        property int fontWeight: 500
        property int tooltipFontSize: 14
        property int textFontSize: 16
        property int textFontSizeMedium: 14
        property int textFontSizeSmall: 12
        property int smallTextFontSize: 10
        property int iconFontSize: 18
        property int iconFontSizeSmall: 14
        property int iconFontSizeMedium: 16
    }
  '';

  home.file.".config/quickshell/Globals.qml".text = ''
    pragma Singleton
    import QtQuick
    import Quickshell

    Singleton {
        id: root
        property var popupContext: PopupContext {}
        property var commonStyles: CommonStyles {}
        property var weatherConsts: WeatherConsts {}
        property var date: new Date()

        Timer {
            interval: 1000
            repeat: true
            running: true
            onTriggered: root.date = new Date()
        }
    }
  '';

  home.file.".config/quickshell/gradient.frag".text = ''
    #version 440
    layout(location = 0) in vec2 qt_TexCoord0;
    layout(location = 0) out vec4 fragColor;

    layout(std140, binding = 0) uniform buf {
        mat4 qt_Matrix;
        float qt_Opacity;
        vec4 baseColor;
        vec4 transparent;
        float rectWidth;
        float rectHeight;
        float cornerRadius;
        float time;
    } ubuf;

    float roundedRectDF(vec2 pt, vec2 size, float radius) {
        vec2 d = abs(pt - size/2.0) - size/2.0 + radius;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
    }

    void main() {
        vec2 pos = qt_TexCoord0;
        float pattern = mod(pos.x * 1.0 + pos.y * 0.0167 - ubuf.time * 0.2, 1.0);
        vec4 color;
        if (pattern < 0.18) color = ubuf.baseColor;
        else if (pattern < 0.37) color = ubuf.transparent;
        else if (pattern < 0.63) color = ubuf.baseColor;
        else if (pattern < 0.85) color = ubuf.transparent;
        else color = ubuf.baseColor;
        float df = roundedRectDF(pos * vec2(ubuf.rectWidth, ubuf.rectHeight), vec2(ubuf.rectWidth, ubuf.rectHeight), ubuf.cornerRadius);
        float mask = 1.0 - smoothstep(-1.0, 0.0, df);
        fragColor = color * ubuf.qt_Opacity * mask;
    }
  '';

  home.file.".config/quickshell/roundedimage.frag".text = ''
    #version 440
    layout(location = 0) in vec2 qt_TexCoord0;
    layout(location = 0) out vec4 fragColor;
    layout(std140, binding = 0) uniform buf {
        mat4 qt_Matrix;
        float qt_Opacity;
        vec2 size;
        float radius;
    };
    layout(binding = 1) uniform sampler2D source;

    void main() {
        vec2 pixPos = qt_TexCoord0 * size;
        vec2 center = size * 0.5;
        vec2 corner = vec2(radius);
        vec2 topLeft = corner;
        vec2 topRight = vec2(size.x - corner.x, corner.y);
        vec2 bottomLeft = vec2(corner.x, size.y - corner.y);
        vec2 bottomRight = size - corner;
        float dist = 0.0;
        if (pixPos.x < corner.x && pixPos.y < corner.y)
            dist = distance(pixPos, topLeft);
        else if (pixPos.x > size.x - corner.x && pixPos.y < corner.y)
            dist = distance(pixPos, topRight);
        else if (pixPos.x < corner.x && pixPos.y > size.y - corner.y)
            dist = distance(pixPos, bottomLeft);
        else if (pixPos.x > size.x - corner.x && pixPos.y > size.y - corner.y)
            dist = distance(pixPos, bottomRight);
        else
            dist = 0.0;
        float alpha = dist > radius ? 0.0 : 1.0;
        fragColor = texture(source, qt_TexCoord0) * alpha * qt_Opacity;
    }
  '';

  home.file.".config/quickshell/WeatherConsts.qml".text = ''
    import QtQuick

    QtObject {
        property var omapiCodeDesc: ({
            "0": "Clear",
            "1": "Mostly Clear",
            "2": "Partly Cloudy",
            "3": "Cloudy",
            "45": "Fog",
            "48": "Freezing Fog",
            "51": "Light Drizzle",
            "53": "Drizzle",
            "55": "Heavy Drizzle",
            "56": "Light Freezing Drizzle",
            "57": "Freezing Drizzle",
            "61": "Light Rain",
            "63": "Rain",
            "65": "Heavy Rain",
            "66": "Light Freezing Rain",
            "67": "Freezing Rain",
            "71": "Light Snow",
            "73": "Snow",
            "75": "Heavy Snow",
            "77": "Light Snow Shower",
            "80": "Light Rain Shower",
            "81": "Rain Shower",
            "82": "Heavy Rain Shower",
            "85": "Snow Shower",
            "86": "Heavy Snow Shower",
            "95": "Thunderstorm",
            "96": "Heavy Thunderstorm",
            "99": "Thunderstorm with Hail"
        })

        property var omapiCode: ({
            "0": "Sunny",
            "1": "PartlyCloudy",
            "2": "Cloudy",
            "3": "VeryCloudy",
            "45": "Fog",
            "48": "Fog",
            "51": "LightShowers",
            "53": "LightRain",
            "55": "HeavyShowers",
            "56": "LightSleetShowers",
            "57": "LightSleet",
            "61": "LightRain",
            "63": "LightRain",
            "65": "HeavyRain",
            "66": "LightSleet",
            "67": "LightSleet",
            "71": "LightSnow",
            "73": "HeavySnow",
            "75": "HeavySnow",
            "77": "LightSnowShowers",
            "80": "LightShowers",
            "81": "HeavyShowers",
            "82": "HeavyShowers",
            "85": "LightSnowShowers",
            "86": "HeavySnowShowers",
            "95": "ThunderyShowers",
            "96": "ThunderyHeavyRain",
            "99": "ThunderySnowShowers"
        })

        property var weatherSymbols: ({
            "Unknown": "air",
            "Cloudy": "cloud",
            "Fog": "foggy",
            "HeavyRain": "rainy",
            "HeavyShowers": "rainy",
            "HeavySnow": "snowing",
            "HeavySnowShowers": "snowing",
            "LightRain": "rainy",
            "LightShowers": "rainy",
            "LightSleet": "rainy",
            "LightSleetShowers": "rainy",
            "LightSnow": "cloudy_snowing",
            "LightSnowShowers": "cloudy_snowing",
            "PartlyCloudy": "partly_cloudy_day",
            "Sunny": "clear_day",
            "ThunderyHeavyRain": "thunderstorm",
            "ThunderyShowers": "thunderstorm",
            "ThunderySnowShowers": "thunderstorm",
            "VeryCloudy": "cloud"
        })

        property var nightWeatherSymbols: ({
            "Unknown": "air",
            "Cloudy": "cloud",
            "Fog": "foggy",
            "HeavyRain": "rainy",
            "HeavyShowers": "rainy",
            "HeavySnow": "snowing",
            "HeavySnowShowers": "snowing",
            "LightRain": "rainy",
            "LightShowers": "rainy",
            "LightSleet": "rainy",
            "LightSleetShowers": "rainy",
            "LightSnow": "cloudy_snowing",
            "LightSnowShowers": "cloudy_snowing",
            "PartlyCloudy": "partly_cloudy_night",
            "Sunny": "clear_night",
            "ThunderyHeavyRain": "thunderstorm",
            "ThunderyShowers": "thunderstorm",
            "ThunderySnowShowers": "thunderstorm",
            "VeryCloudy": "cloud"
        })
    }
  '';

  home.file.".config/quickshell/widgets/Stats.qml".text = ''
    import QtQuick
    import Quickshell
    import Quickshell.Io
    import QtQuick.Layouts
    import QtQuick.Controls

    Item {
        id: root
        implicitHeight: 30
        implicitWidth: layout.width

        property string updateInterval: "2s"
        property string cpuUsage: ""

        Process {
            id: cpuProcess
            running: true
            command: ["${pkgs.coreutils}/bin/sh", "-c", "top -bn1 | head -n3 | grep '%Cpu' | awk '{print $2}'"]
            stdout: SplitParser {
                onRead: function (line) {
                    root.cpuUsage = line + "%";
                }
            }
        }

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: 10

            Item {
                Layout.preferredHeight: cpuUsageLayout.height
                Layout.preferredWidth: cpuUsageLayout.width

                MouseArea {
                    id: cpuMouseArea
                    width: cpuUsageLayout.width
                    height: cpuUsageLayout.height
                    hoverEnabled: true
                    onEntered: cpuTooltip.relativeItem = cpuUsageLayout
                    onExited: cpuTooltip.relativeItem = null

                    RowLayout {
                        id: cpuUsageLayout
                        spacing: 3

                        Text {
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            text: "\uE8B8"
                            color: "#ffffff"
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            font.family: "Ubuntu"
                            font.pixelSize: 16
                            color: "#ffffff"
                            text: root.cpuUsage
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                BarTooltip {
                    id: cpuTooltip
                    hideDelay: 0
                    contentDelegate: Text {
                        text: "CPU Usage\n" + root.cpuUsage
                        color: "#ffffff"
                        font.family: "Ubuntu"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/NowPlaying.qml".text = ''
    import QtQuick
    import Quickshell
    import Quickshell.Services.Mpris
    import QtQuick.Layouts

    Item {
        id: root
        implicitHeight: 30
        implicitWidth: titleText.implicitWidth

        property MprisPlayer player: Mpris.players.values[0] ?? null

        Text {
            id: titleText
            text: root.player?.trackTitle || ""
            color: "#ffffff"
            font.family: "Ubuntu"
            font.pixelSize: 16
        }
    }
  '';

  home.file.".config/quickshell/widgets/Workspaces.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Hyprland
    import Quickshell.Widgets
    import "root:/"

    BarWidget {
        id: root
        Layout.alignment: Qt.AlignLeft
        property int workspaces: 10
        Layout.fillHeight: true
        widgetAnchors.margins: 0

        RowLayout {
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            Repeater {
                model: root.workspaces

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24

                    Rectangle {
                        id: wsRect
                        anchors.fill: parent

                        property int wsId: index + 1
                        property bool isActive: Hyprland.focusedMonitor?.activeWorkspace.id === wsId
                        property bool hasWindows: {
                            for (const ws of Hyprland.workspaces.values) {
                                if (ws.id === wsId)
                                    return true;
                            }
                            return false;
                        }
                        property bool hasNextWindow: {
                            if (index < workspaces - 1) {
                                for (const ws of Hyprland.workspaces.values) {
                                    if (ws.id === (wsId + 1))
                                        return true;
                                }
                            }
                            return false;
                        }
                        property bool hasPrevWindow: {
                            if (index > 0) {
                                for (const ws of Hyprland.workspaces.values) {
                                    if (ws.id === (wsId - 1))
                                        return true;
                                }
                            }
                            return false;
                        }

                        color: {
                            if (mouseArea.containsMouse && wsRect.hasWindows)
                                return "#3e31ad";
                            if (isActive)
                                return "#c6c0ff";
                            if (hasWindows)
                                return "#464459";
                            return "transparent";
                        }
                        radius: 99

                        Rectangle {
                            z: -1
                            visible: wsRect.hasWindows
                            anchors.fill: parent
                            color: "#464459"
                            radius: 99

                            Rectangle {
                                visible: wsRect.hasNextWindow && wsRect.hasWindows
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                    rightMargin: 0
                                }
                                width: parent.width / 2
                                color: parent.color
                                radius: 0
                            }

                            Rectangle {
                                visible: wsRect.hasPrevWindow && wsRect.hasWindows
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    leftMargin: 0
                                }
                                width: parent.width / 2
                                color: parent.color
                                radius: 0
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                                easing.type: Easing.Bezier
                                easing.bezierCurve: [0, 1, 0, 1]
                            }
                        }

                        Text {
                            id: wsText
                            anchors.centerIn: parent
                            text: wsRect.wsId
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: {
                                if (mouseArea.containsMouse) {
                                    if (wsRect.isActive)
                                        return "#260f98";
                                    if (wsRect.hasWindows)
                                        return "#e5dfff";
                                    return "#c6c0ff";
                                }
                                if (wsRect.isActive)
                                    return "#260f98";
                                if (wsRect.hasWindows)
                                    return "#e3dff8";
                                return "#666666";
                            }
                            font.pixelSize: Globals.commonStyles.textFontSize
                            font.family: Globals.commonStyles.fontFamilySans
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: !wsRect.isActive
                            acceptedButtons: wsRect.isActive ? Qt.NoButton : Qt.LeftButton
                            onClicked: {
                                Hyprland.dispatch(`workspace ${wsRect.wsId}`);
                            }
                            onWheel: function (event) {
                                if (event.angleDelta.y > 0) {
                                    if (Hyprland.focusedMonitor.activeWorkspace.id === root.workspaces) {
                                        return;
                                    }
                                    Hyprland.dispatch(`workspace +1`);
                                } else {
                                    if (Hyprland.focusedMonitor.activeWorkspace.id === 1) {
                                        return;
                                    }
                                    Hyprland.dispatch(`workspace -1`);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/ActiveWindow.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Widgets
    import "root:/"

    BarWidget {
        id: wrapper

        function getIcon() {
            var icon = Quickshell.iconPath(ToplevelManager.activeToplevel.appId.toLowerCase(), true);
            if (!icon) {
                icon = Quickshell.iconPath(ToplevelManager.activeToplevel.appId, true);
            }
            if (!icon) {
                icon = Quickshell.iconPath(ToplevelManager.activeToplevel.title, true);
            }
            if (!icon) {
                icon = Quickshell.iconPath(ToplevelManager.activeToplevel.title.toLowerCase(), "application-x-executable");
            }
            return icon;
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, parent.width)
            height: parent.height
            spacing: 4

            IconImage {
                id: icon
                implicitHeight: 20
                implicitWidth: 20
                source: ToplevelManager.activeToplevel ? getIcon() : ""
            }

            Text {
                id: text
                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth + 1
                horizontalAlignment: Text.AlignLeft
                text: ToplevelManager.activeToplevel?.title ?? ""
                color: Globals.commonStyles.textColor
                font.pointSize: Globals.commonStyles.textFontSizeSmall
                font.family: Globals.commonStyles.fontFamily
                font.weight: Globals.commonStyles.fontWeight
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/Power.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Services.UPower
    import "root:/"

    Loader {
        visible: UPower.displayDevice != null && UPower.displayDevice.type === UPowerDeviceType.Battery
        active: visible

        sourceComponent: MouseArea {
            id: mouseArea
            hoverEnabled: true

            implicitWidth: widget.implicitWidth
            implicitHeight: widget.implicitHeight

            BarWidget {
                id: widget
                anchors.fill: parent

                RowLayout {
                    anchors.fill: parent
                    spacing: 3

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        font.family: Globals.commonStyles.iconFontFamily
                        font.pixelSize: Globals.commonStyles.iconFontSize
                        color: Globals.commonStyles.textColor
                        text: {
                            const device = UPower.displayDevice;
                            const percentage = device.percentage;

                            if (device.state === UPowerDeviceState.Charging) {
                                return "battery_charging_full";
                            }
                            if (device.state === UPowerDeviceState.FullyCharged) {
                                return "battery_full";
                            }

                            const batteryLevel = Math.floor(6 * percentage);
                            return `battery_${batteryLevel}_bar`;
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        font.family: Globals.commonStyles.fontFamily
                        font.weight: Globals.commonStyles.fontWeight
                        font.pixelSize: Globals.commonStyles.textFontSize
                        color: Globals.commonStyles.textColor
                        text: `${Math.floor(UPower.displayDevice.percentage * 100)}%`
                    }
                }
            }

            BarTooltip {
                id: powerTooltip
                hideDelay: 0
                relativeItem: mouseArea.containsMouse ? widget : null
                contentDelegate: Text {
                    text: {
                        const device = UPower.displayDevice;

                        let state = UPowerDeviceState.toString(device.state);
                        switch (device.state) {
                        case UPowerDeviceState.Charging:
                            state = "Charging";
                            break;
                        case UPowerDeviceState.PendingCharge:
                            state = "Not Charging";
                            break;
                        case UPowerDeviceState.Discharging:
                            state = "Discharging";
                            break;
                        case UPowerDeviceState.FullyCharged:
                            state = "Fully Charged";
                            break;
                        }

                        const time = device.timeToEmpty || device.timeToFull;
                        if (time != 0) {
                            if (state != "")
                                state += "\n";
                            const minutes = Math.floor(time / 60).toString().padStart(2, '0');
                            const seconds = (time % 60).toString().padStart(2, '0');
                            state += `${minutes}:${seconds} remains`;
                        }

                        return state;
                    }
                    color: Globals.commonStyles.textColor
                    font.family: Globals.commonStyles.fontFamily
                    font.pixelSize: Globals.commonStyles.tooltipFontSize
                    font.weight: Globals.commonStyles.fontWeight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/SystemTray.qml".text = ''
    import QtQuick
    import QtQuick.Controls
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Widgets
    import Quickshell.Services.SystemTray
    import "root:/"

    BarWidget {
        id: root
        widgetAnchors.margins: 0
        widgetAnchors.leftMargin: 5
        widgetAnchors.rightMargin: 0
        height: 30
        implicitHeight: 30
        implicitWidth: trayLayout.implicitWidth + 5

        RowLayout {
            id: trayLayout
            anchors.fill: parent
            anchors.bottomMargin: 0
            spacing: 5

            Repeater {
                model: SystemTray.items

                MouseArea {
                    id: delegate
                    required property SystemTrayItem modelData
                    property alias item: delegate.modelData

                    Layout.fillHeight: true
                    implicitWidth: icon.implicitWidth + 5

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true

                    onClicked: event => {
                        if (event.button == Qt.LeftButton) {
                            item.activate();
                        } else if (event.button == Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (event.button == Qt.RightButton && item.hasMenu) {
                            const window = QsWindow.window;
                            const widgetRect = window.contentItem.mapFromItem(delegate, 0, delegate.height, delegate.width, delegate.height);
                            menuAnchor.anchor.rect = widgetRect;
                            menuAnchor.open();
                        }
                    }

                    onWheel: event => {
                        event.accepted = true;
                        const points = event.angleDelta.y / 120;
                        item.scroll(points, false);
                    }

                    IconImage {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        source: item && item.icon ? item.icon : ""
                        visible: status === Image.Ready
                        implicitSize: 20
                    }
                    BarTooltip {
                        relativeItem: delegate.containsMouse ? delegate : null
                        hoverable: true
                        showBackground: true
                        hideDelay: 0
                        Label {
                            font.family: Globals.commonStyles.fontFamily
                            font.pixelSize: Globals.commonStyles.tooltipFontSize
                            font.weight: Globals.commonStyles.fontWeight
                            color: Globals.commonStyles.textColor
                            text: delegate.item ? (delegate.item.tooltipTitle || delegate.item.id || "") : ""
                        }
                    }

                    QsMenuAnchor {
                        id: menuAnchor
                        menu: item.menu
                        anchor.window: delegate.QsWindow.window ?? null
                        anchor.adjustment: PopupAdjustment.Flip
                    }
                }
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/Clock.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import "root:/"

    BarWidget {
        id: clockWidget
        Layout.minimumWidth: clockLayout.implicitWidth + 10
        Layout.minimumHeight: clockLayout.implicitHeight
        widgetAnchors.margins: 10

        property bool calendarOpen: false
        property bool twelveHourClock: false
        property bool reverseDayMonth: false

        Rectangle {
            id: background
            anchors.margins: 0
            anchors.centerIn: parent
            width: clockLayout.implicitWidth + 10
            height: 30
            color: "#40ffffff"
            radius: 0
            opacity: mouseArea.containsMouse ? 0.2 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        Column {
            id: clockLayout
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.verticalCenter
            rightPadding: 6
            spacing: 0

            Text {
                id: timeText
                anchors.right: parent.horizontalCenter
                text: {
                    let now = Globals.date;
                    return now.toLocaleString(Qt.locale(), (twelveHourClock ? "hh:mm AP" : "HH:mm"));
                }
                font.pixelSize: Globals.commonStyles.textFontSizeMedium
                font.family: Globals.commonStyles.fontFamily
                font.weight: Globals.commonStyles.fontWeight
                color: Globals.commonStyles.textColor
                opacity: 1
            }

            Text {
                id: dateText
                anchors.right: parent.horizontalCenter
                text: {
                    let now = Globals.date;
                    let dayName = now.toLocaleDateString(Qt.locale(), "ddd");
                    dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1);
                    let day = now.getDate();
                    let suffix;
                    if (day > 3 && day < 21)
                        suffix = 'th';
                    else
                        switch (day % 10) {
                        case 1:
                            suffix = "st";
                            break;
                        case 2:
                            suffix = "nd";
                            break;
                        case 3:
                            suffix = "rd";
                            break;
                        default:
                            suffix = "th";
                        }
                    let month = now.toLocaleDateString(Qt.locale(), "MMM");
                    return `${dayName}, ` + (reverseDayMonth ? `${month} ${day}${suffix}` : `${day}${suffix} ${month}`);
                }
                font.pixelSize: Globals.commonStyles.smallTextFontSize
                font.family: Globals.commonStyles.fontFamily
                font.weight: Globals.commonStyles.fontWeight
                color: Globals.commonStyles.textColor
                opacity: 1
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.margins: 0
            hoverEnabled: true
            onClicked: calendarOpen = !calendarOpen
        }

        Calander {
            calendarOpen: clockWidget.calendarOpen
            clockLayout: clockLayout
        }
    }
  '';

  home.file.".config/quickshell/widgets/Weather.qml".text = ''
    import QtQuick
    import Quickshell
    import QtQuick.Layouts
    import QtQuick.Window
    import "root:/"

    BarWidget {
        id: root
        implicitHeight: 30
        implicitWidth: mainRect.width

        property string city: "Bentonville"
        property bool isAmerican: true
        property int updateInterval: 900
        property string weatherDescription: ""
        property var weather: {}

        property Timer retryTimer: Timer {
            interval: 30000
            repeat: false
            running: false
            onTriggered: getGeocoding()
        }

        Timer {
            interval: root.updateInterval * 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: getGeocoding()
        }

        function getTemp(temp, tempUnit) {
            return temp + tempUnit;
        }

        function getWeatherSymbol(weatherCode, weatherSymbols, nightWeatherSymbols) {
            const dt = new Date();
            const hour = dt.getHours();
            const isNight = hour <= 7 || hour >= 20;
            const code = Globals.weatherConsts.omapiCode[weatherCode] || "Unknown";
            return isNight ? Globals.weatherConsts.nightWeatherSymbols[code] || Globals.weatherConsts.weatherSymbols["Unknown"] : Globals.weatherConsts.weatherSymbols[code] || Globals.weatherConsts.weatherSymbols["Unknown"];
        }

        function updateWeather() {
            const weatherCode = weather.current.weather_code;
            weatherIcon.text = getWeatherSymbol(weatherCode);
            tempLabel.text = getTemp(Math.round(weather.current.temperature_2m), weather.current_units.temperature_2m);
        }

        function getGeocoding() {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", `https://geocoding-api.open-meteo.com/v1/search?name=${city}&count=1&language=en&format=json`);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        const geocoding = JSON.parse(xhr.responseText);
                        if (geocoding.results.length > 0) {
                            const lat = geocoding.results[0].latitude;
                            const lng = geocoding.results[0].longitude;
                            getWeather(lat, lng);
                        } else {
                            console.error("No geocoding results found");
                            retryTimer.running = true;
                        }
                    } else {
                        console.error("Geocoding request failed with status:", xhr.status);
                        retryTimer.running = true;
                    }
                }
            };
            xhr.onerror = function () {
                console.error("Geocoding request failed with network error");
                retryTimer.running = true;
            };
            xhr.send();
        }

        function getWeather(lat, lng) {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current=temperature_2m,is_day,weather_code&temperature_unit=` + (isAmerican ? "fahrenheit" : "celsius"));
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        weather = JSON.parse(xhr.responseText);
                        updateWeather();
                        weatherDescription = Globals.weatherConsts.omapiCodeDesc[weather.current.weather_code];
                    } else {
                        console.error("Weather request failed with status:", xhr.status);
                        retryTimer.running = true;
                    }
                }
            };
            xhr.onerror = function () {
                console.error("Weather request failed with network error");
                retryTimer.running = true;
            };
            xhr.send();
        }

        Item {
            id: mainRect
            height: parent.height
            width: layout.width + 10

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true

                BarTooltip {
                    relativeItem: mouseArea.containsMouse && weatherDescription !== "" ? mouseArea : null
                    hoverable: true
                    showBackground: true
                    hideDelay: 0
                    contentDelegate: Component {
                        Text {
                            font.family: Globals.commonStyles.fontFamily
                            font.pixelSize: Globals.commonStyles.tooltipFontSize
                            font.weight: Globals.commonStyles.fontWeight
                            color: Globals.commonStyles.tooltipTextColor
                            text: weatherDescription
                        }
                    }
                }
            }

            RowLayout {
                id: layout
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                spacing: 5

                Text {
                    id: weatherIcon
                    font.family: Globals.commonStyles.iconFontFamily
                    font.pixelSize: Globals.commonStyles.iconFontSizeMedium
                    color: Globals.commonStyles.textColor
                    text: "rainy"
                }

                Text {
                    id: tempLabel
                    font.family: Globals.commonStyles.fontFamily
                    font.pixelSize: Globals.commonStyles.textFontSize
                    color: Globals.commonStyles.textColor
                    font.weight: Globals.commonStyles.fontWeight
                }
            }
        }

        Component.onCompleted: getGeocoding()
    }
  '';

  home.file.".config/quickshell/widgets/BarTooltip.qml".text = ''
    import QtQuick
    import QtQuick.Controls
    import Quickshell

    Popup {
        id: root
        property Item relativeItem
        property bool showBackground: true
        property bool hoverable: false
        property int hideDelay: 200
        property alias contentDelegate: contentLoader.sourceComponent

        x: contentLoader.width > 0 ? -(contentLoader.width/2 - (relativeItem ? relativeItem.width/2 : 0)) : 0
        y: relativeItem ? relativeItem.height + 5 : 0
        margins: 0
        visible: relativeItem != null
        width: contentLoader.width
        height: contentLoader.height

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
        }

        background: Rectangle {
            visible: showBackground
            color: Globals.commonStyles.tooltipBackground
            radius: 5
        }

        Timer {
            id: hideTimer
            interval: root.hideDelay
            running: false
            repeat: false
            onTriggered: {
                if (!root.hoverable || !root.hovered)
                    root.relativeItem = null;
            }
        }

        contentItem: Loader {
            id: contentLoader
        }

        Connections {
            target: relativeItem
            function onVisibleChanged() {
                if (!relativeItem.visible)
                    root.relativeItem = null;
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/Calander.qml".text = ''
    import QtQuick
    import QtQuick.Controls
    import Quickshell
    import "root:/"

    Popup {
        id: root
        property bool calendarOpen: false
        property Item clockLayout
        visible: calendarOpen
        anchors.centerIn: clockLayout
        margins: 0
        width: calendar.width
        height: calendar.height
        background: Rectangle {
            color: Globals.commonStyles.tooltipBackground
            radius: 5
        }

        Calendar {
            id: calendar
            onClicked: {
                root.calendarOpen = false
            }
        }
    }
  '';

  home.file.".config/quickshell/widgets/IconButton.qml".text = ''
    import QtQuick
    import QtQuick.Controls
    import Quickshell
    import Quickshell.Widgets
    import "root:/"

    BarWidget {
        id: root
        property string icon: ""
        property bool toggleable: false
        property bool toggled: false
        signal clicked()

        implicitWidth: mouseArea.implicitWidth
        implicitHeight: mouseArea.implicitHeight

        MouseArea {
            id: mouseArea
            implicitWidth: iconText.implicitWidth
            implicitHeight: iconText.implicitHeight
            hoverEnabled: true
            onClicked: {
                if (toggleable)
                    toggled = !toggled;
                root.clicked();
            }
        }

        Text {
            id: iconText
            anchors.centerIn: parent
            font.family: Globals.commonStyles.iconFontFamily
            font.pixelSize: Globals.commonStyles.iconFontSize
            text: root.icon
            color: mouseArea.containsMouse ? "#cccccc" : Globals.commonStyles.textColor
        }
    }
  '';
  home.file.".config/quickshell/PopupContext.qml".text = ''
    import QtQuick

    QtObject {
        property var popup: null
    }
  '';
  systemd.user.services.quickshell = {
    description = "Quickshell Bar for Niri and Hyprland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell --file ${config.home.homeDirectory}/.config/quickshell/bar.qml";
      Restart = "always";
    };
  };

  # User-specific packages
  home.packages = with pkgs; [
    kitty
    foot
    vivaldi
    obsidian
    mpv
    home-manager
    pwvucontrol
    nemo
  ];
}
