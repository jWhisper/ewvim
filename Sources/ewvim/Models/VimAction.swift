import Foundation
import ApplicationServices

enum VimAction {
  case switchMode(VimMode)
  case simulateKeyPress(CGKeyCode, UInt64)
  case executeCommand(VimCommand, count: Int)
  case executeAction(() -> Void)
  case compound([VimAction])
}
