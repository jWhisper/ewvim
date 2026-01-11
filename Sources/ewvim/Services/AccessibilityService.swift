import Foundation
import ApplicationServices

class AccessibilityService {
  static let shared = AccessibilityService()

  private init() {}

  var isEnabled: Bool {
    return AXIsProcessTrusted()
  }

  func requestPermissions() {
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
    _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  func getFocusedElement() -> AXUIElement? {
    let systemWideElement = AXUIElementCreateSystemWide()

    var focused: AnyObject?
    let result = AXUIElementCopyAttributeValue(
      systemWideElement,
      kAXFocusedUIElementAttribute as CFString,
      &focused
    )

    return result == .success ? (focused as! AXUIElement) : nil
  }

  func getText(from element: AXUIElement) -> String? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(
      element,
      kAXValueAttribute as CFString,
      &value
    )

    return result == .success ? (value as? String) : nil
  }

  func setText(_ text: String, in element: AXUIElement) -> Bool {
    let value = text as AnyObject
    let result = AXUIElementSetAttributeValue(
      element,
      kAXValueAttribute as CFString,
      value
    )

    return result == .success
  }

  func getSelectedRange(from element: AXUIElement) -> NSRange? {
    var rangeValue: AnyObject?
    let result = AXUIElementCopyAttributeValue(
      element,
      kAXSelectedTextRangeAttribute as CFString,
      &rangeValue
    )

    guard result == .success else {
      return nil
    }

    return NSRange(location: 0, length: 0)
  }

  func setSelectedRange(_ range: NSRange, in element: AXUIElement) -> Bool {
    return false
  }
}