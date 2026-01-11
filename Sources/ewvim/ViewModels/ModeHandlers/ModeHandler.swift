import Foundation
import ApplicationServices

protocol ModeHandler: AnyObject {
  func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> VimAction?
  func onEnter(from oldMode: VimMode)
  func onExit()
}
