import Quickshell
import "modules/topbar"
import "modules/background"
import "modules/launcher"
import "modules/clipboard"
import "modules/monitors"

ShellRoot {
    id: root

    Background {}
    TopBar {}
    Launcher {}
    Clipboard {}
    MonitorManager {}
}
