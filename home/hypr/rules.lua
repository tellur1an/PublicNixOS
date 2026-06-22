-- Window rules: app placement and behavior.
local lib = require("lib")
local rule = lib.rule

-- Stop apps maximizing themselves (games handle their own fullscreen below).
rule({ name = "no-self-maximize", match = { class = ".*" }, suppress_event = "maximize" })

rule({ name = "comm-signal", match = { class = "^(signal|Signal)$" }, tile = true, workspace = "2 silent", scrolling_width = 0.20 })
rule({ name = "comm-discord", match = { class = "^(legcord|discord|Discord|vesktop|Vesktop|dev\\.vencord\\.Vesktop)$" }, tile = true, workspace = "2 silent", scrolling_width = 0.34 })
rule({ name = "comm-simplex", match = { class = "^(chat-simplex-desktop-MainKt)$" }, workspace = "2 silent", scrolling_width = 0.20 })
rule({ name = "comm-nheko", match = { class = "^(nheko|io\\.github\\.NhekoReborn\\.Nheko)$" }, tile = true, workspace = "2 silent", scrolling_width = 0.20 })
rule({ name = "comm-emacs", match = { class = "^(emacs|Emacs)$" }, tile = true, workspace = "2 silent", scrolling_width = 0.46 })

rule({ name = "browser-brave", match = { class = "^(brave|brave-browser|brave-browser-beta|brave-origin|brave-origin-beta|brave-origin-nightly)$" }, tile = true, workspace = "3 silent" })
rule({ name = "browser-vivaldi", match = { class = "^(vivaldi|vivaldi-stable)$" }, workspace = "3 silent" })
rule({ name = "browser-firefox", match = { class = "^(firefox|mullvadbrowser|Mullvad Browser)$" }, workspace = "3 silent" })
rule({ name = "browser-floorp-zen", match = { class = "^(floorp|Floorp|one\\.ablaze\\.floorp|zen|zen-browser|zen_browser|app\\.zen_browser\\.zen|io\\.github\\.zen_browser\\.zen)$" }, tile = true, workspace = "3 silent" })

rule({ name = "launcher-steam", match = { class = "^(steam|Steam)$" }, tile = true, workspace = "4 silent", no_shortcuts_inhibit = true, border_size = 0, no_shadow = true, no_blur = true })
rule({ name = "launcher-steam-title", match = { title = "^(Steam|Friends List)$" }, workspace = "4 silent" })
rule({ name = "launcher-heroic", match = { class = "^(Heroic|heroic)$" }, tile = true, workspace = "4 silent" })
rule({ name = "launcher-lutris", match = { class = "^(net\\.lutris\\.Lutris)$" }, tile = true, workspace = "4 silent" })

-- suppress_event blocks the client's own fullscreen request at map time so the
-- silent move to ws5 happens first (XWayland games fullscreening on map pinned
-- themselves to the active workspace); the rule's fullscreen = true then
-- re-fullscreens it on ws5
rule({ name = "game-steam-app", match = { class = "^(steam_app_.*)$" }, workspace = "5 silent", suppress_event = "fullscreen maximize", immediate = true, idle_inhibit = "always", allows_input = true, render_unfocused = true, border_size = 0, fullscreen = true, no_shortcuts_inhibit = true, content = "game" })
rule({ name = "game-gamescope", match = { class = "^(gamescope)$" }, workspace = "5 silent", immediate = true, idle_inhibit = "always", border_size = 0, fullscreen = true, no_shortcuts_inhibit = true, content = "game" })
rule({ name = "game-wine", match = { class = "^(wine|wine-preloader|steam_proton|proton)$" }, workspace = "5 silent", no_shortcuts_inhibit = true, content = "game" })
-- Native-Wayland Proton (PROTON_ENABLE_WAYLAND=1): wine sets app-id to the
-- exe name (e.g. pathofexilesteam.exe) instead of steam_app_*, so match any
-- *.exe class. Wine on this machine = games only.
rule({ name = "game-wine-wayland", match = { class = "^.*\\.exe$" }, workspace = "5 silent", suppress_event = "fullscreen maximize", immediate = true, idle_inhibit = "always", allows_input = true, render_unfocused = true, border_size = 0, fullscreen = true, no_shortcuts_inhibit = true, content = "game" })

rule({ name = "media-vlc", match = { class = "^(vlc|kew|moe\\.tsuna\\.tsukimi)$" }, workspace = "6 silent", float = true, size = { 1600, 900 }, idle_inhibit = "always" })
rule({ name = "media-mpv", match = { class = "^(mpv)$" }, workspace = "6 silent", tile = true, idle_inhibit = "always" })
rule({ name = "media-grayjay", match = { class = "^(cef)$", title = "^(Grayjay)$" }, workspace = "6 silent" })
rule({ name = "media-webapps", match = { class = "^(yt-x|yt-xr|rumble-x)$" }, workspace = "6" })

rule({ name = "system-streamcontroller", match = { class = "^(streamcontroller|StreamController)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-core447-streamcontroller", match = { class = "^(com\\.core447\\.StreamController)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-openrgb", match = { class = "^(openrgb|OpenRGB|org\\.openrgb\\.OpenRGB)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-keepassxc", match = { class = "^(keepassxc|KeePassXC|org\\.keepassxc\\.KeePassXC)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-mullvad", match = { class = "^(Mullvad VPN)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-joplin", match = { class = "^(Joplin|joplin|@joplinapp-desktop)$" }, workspace = "7 silent", tile = true })
rule({ name = "system-streamdeck", match = { class = "^(streamdeck|Streamdeck)$" }, workspace = "7 silent", tile = true })

rule({ name = "mail-tuta", match = { class = "^(tutanota-desktop)$" }, workspace = "8 silent", no_screen_share = true })
rule({ name = "mail-thunderbird", match = { class = "^(thunderbird)$" }, tile = true, workspace = "8 silent" })
rule({ name = "mail-proton-bridge", match = { class = "^(ch\\.proton\\.bridge-gui)$" }, workspace = "8 silent", no_screen_share = true })

rule({ name = "float-pwvucontrol", match = { class = "^(com\\.saivert\\.pwvucontrol)$" }, float = true })
rule({ name = "float-wiremix", match = { class = "^(wiremix)$" }, float = true, size = { 900, 600 }, center = true })
rule({ name = "terminal-kitty-no-blur", match = { class = "^(kitty|scratchterm|wiremix)$" }, no_blur = true })
rule({ name = "float-blueman", match = { class = "^(blueman-manager)$" }, float = true, size = { 1200, 800 } })
rule({ name = "float-file-roller", match = { class = "^(org\\.gnome\\.FileRoller)$" }, float = true, size = { 1200, 800 } })
rule({ name = "float-ark", match = { class = "^(org\\.kde\\.ark)$" }, float = true, size = { 1200, 800 } })
rule({ name = "float-gearlever", match = { class = "^(it\\.mijorus\\.gearlever)$" }, float = true, size = { 1200, 800 } })
rule({ name = "float-calculator", match = { class = "^(org\\.gnome\\.Calculator)$" }, float = true })
rule({ name = "float-protonplus", match = { class = "^(com\\.vysp3r\\.ProtonPlus)$" }, float = true })
rule({ name = "float-bleachbit", match = { class = "^(org\\.bleachbit\\.BleachBit)$" }, float = true })
rule({ name = "ghostty-dropdown", match = { class = "^(com\\.mitchellh\\.ghostty-dropdown)$" }, float = true, size = { 3440, 600 } })

rule({ name = "scratchterm", match = { class = "^(scratchterm)$" }, float = true, workspace = "special:scratch", size = { 2752, 1008 }, center = true })
rule({ name = "steamwebhelper", match = { class = "^(steamwebhelper)$" }, float = true, allows_input = true, render_unfocused = true, border_size = 0, no_shadow = true, no_blur = true })
rule({ name = "fullscreen-idle-inhibit", match = { fullscreen = true }, idle_inhibit = "always" })
rule({ name = "picture-in-picture", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })
rule({ name = "sharing-prompt", match = { title = "^(Sharing)$" }, float = true })
rule({ name = "launcher-window", match = { class = "^(launcher)$" }, float = true, no_anim = true, size = { 1000, 750 }, center = true })
