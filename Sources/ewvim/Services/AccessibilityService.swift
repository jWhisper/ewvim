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

    print("         📍 AX.getFocusedElement: result=\(result.rawValue), hasValue=\(focused != nil)")
    if result == .success, let role = focused {
      var roleValue: AnyObject?
      _ = AXUIElementCopyAttributeValue(role as! AXUIElement, kAXRoleAttribute as CFString, &roleValue)
      print("         📍 Role: \(roleValue as? String ?? "unknown")")
    }

    return result == .success ? (focused as! AXUIElement) : nil
  }

  func getText(from element: AXUIElement) -> String? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(
      element,
      kAXValueAttribute as CFString,
      &value
    )

    print("         📍 AX.getText: result=\(result.rawValue), hasValue=\(value != nil)")
    if let text = value as? String {
      print("         📍 Text length: \(text.count), preview: \"\(text.prefix(50))...\"")
    }

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

    print("         📍 AX.getSelectedRange: result=\(result.rawValue), hasValue=\(rangeValue != nil)")

    guard result == .success,
          let rangeAXValue = rangeValue,
          CFGetTypeID(rangeAXValue) == AXValueGetTypeID() else {
      print("         ❌ Failed to get range or not AXValue type")
      return nil
    }

    var range = CFRange(location: 0, length: 0)
    let success = withUnsafePointer(to: &range) { ptr in
      AXValueGetValue(rangeAXValue as! AXValue, .cfRange, UnsafeMutableRawPointer(mutating: ptr))
    }

    guard success else {
      print("         ❌ AXValueGetValue failed")
      return nil
    }

    print("         ✅ Range: location=\(range.location), length=\(range.length)")
    return NSRange(location: range.location, length: range.length)
  }

  func setSelectedRange(_ range: NSRange, in element: AXUIElement) -> Bool {
    return false
  }
}