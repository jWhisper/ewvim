import SwiftUI

extension Notification.Name {
  static let appWillTerminate = Notification.Name("appWillTerminate")
}

@main
struct ewvimApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 400, height: 300)
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var sigintSource: DispatchSourceSignal?
  private var sigtermSource: DispatchSourceSignal?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    // Handle Ctrl+C for graceful shutdown using DispatchSource
    sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sigintSource?.setEventHandler { [weak self] in
      print("\n👋 ewvim received interrupt, shutting down...")
      self?.cleanup()
      NSApp.terminate(nil)
    }
    sigintSource?.resume()

    sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    sigtermSource?.setEventHandler { [weak self] in
      print("\n👋 ewvim received term signal, shutting down...")
      self?.cleanup()
      NSApp.terminate(nil)
    }
    sigtermSource?.resume()
  }

  private func cleanup() {
    sigintSource?.cancel()
    sigtermSource?.cancel()
    sigintSource = nil
    sigtermSource = nil
    // Notify subscribers to cleanup
    NotificationCenter.default.post(name: .appWillTerminate, object: nil)
  }

  func applicationWillTerminate(_ notification: Notification) {
    print("👋 ewvim is terminating...")
    cleanup()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }
}