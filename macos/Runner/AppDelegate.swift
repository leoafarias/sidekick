import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        for window in NSApp.windows {
        if !window.isVisible {
            window.setIsVisible(true)
        }
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
        }
    }
    return true
  }

  // TODO: Added this due to the following issue
  // https://github.com/tekartik/process_run.dart/issues/36#issuecomment-770226249
  // Once this is addressed it can be removed
   override func applicationDidBecomeActive(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN) //Ignore signal
  }
}
