import Foundation
import ApplicationServices

/// Represents the result of processing a key in a sequence
enum KeySequenceResult {
  /// Still waiting for more keys to complete sequence
  case waiting
  /// Sequence matched and action was performed
  case matched
  /// Sequence didn't match - should pass through without buffering
  case mismatched
  /// Sequence timed out - pass through the single buffered key
  case timeout(sendKey: Bool, keyCode: CGKeyCode)
}

/// Configuration for a key sequence detection
struct KeySequenceConfig {
  /// The sequence of keys to match (e.g., "jk", "gg")
  let sequence: String
  /// Action to perform when sequence matches
  let action: () -> Void
  /// Timeout in seconds before considering sequence incomplete
  let timeout: TimeInterval
}

/// Detects and handles multi-key sequences like "jk", "gg"
class KeySequenceDetector {
  private var pendingSequence: String = ""
  private var pendingKeyCode: CGKeyCode?
  private var workItem: DispatchWorkItem?
  private var configs: [String: KeySequenceConfig] = [:]
  private var isSendingSyntheticKey = false

  init(configs: [KeySequenceConfig]) {
    for config in configs {
      self.configs[config.sequence] = config
    }
  }

  /// Called for each key press.
  func onKey(_ key: String, keyCode: CGKeyCode) -> KeySequenceResult {
    // If we're currently sending a synthetic key, pass it through without processing
    if isSendingSyntheticKey {
      isSendingSyntheticKey = false
      return .timeout(sendKey: false, keyCode: 0)
    }

    // If we have a pending work item (first key buffered), handle the second key
    if workItem != nil {
      workItem?.cancel()
      workItem = nil

      let fullSequence = pendingSequence + key

      // Check if this matches any configured sequence
      if let config = configs[fullSequence] {
        // Sequence matched!
        pendingSequence = ""
        pendingKeyCode = nil
        config.action()
        return .matched
      }

      // Sequence didn't match - the first key was a timeout case
      // We need to send the first key, then handle the second key normally
      if let code = pendingKeyCode {
        // The second key (current one) will be passed through
        // The first key needs to be sent as synthetic
        pendingSequence = ""
        pendingKeyCode = nil

        isSendingSyntheticKey = true
        KeySimulator.press(keyCode: code, modifiers: 0)

        // The second key (current `key`) should also pass through
        // Return false so both keys go through (first as synthetic, second as normal)
        return .timeout(sendKey: false, keyCode: 0)
      }

      pendingSequence = ""
      return .mismatched
    }

    // No pending keys - check if this key could start a sequence
    for (sequence, config) in configs where sequence.hasPrefix(key) {
      // This key could start a sequence, buffer it
      pendingSequence = key
      pendingKeyCode = keyCode

      // Set up timeout
      let workItem = DispatchWorkItem { [weak self] in
        guard let self = self else { return }
        // Timeout expired - return the buffered key
        if let code = self.pendingKeyCode {
          self.isSendingSyntheticKey = true
          KeySimulator.press(keyCode: code, modifiers: 0)
        }
        self.pendingSequence = ""
        self.pendingKeyCode = nil
        self.workItem = nil
      }
      self.workItem = workItem

      // Return special value to tell caller we're waiting
      // The caller should not return a result yet - they should wait
      DispatchQueue.main.asyncAfter(deadline: .now() + config.timeout, execute: workItem)
      return .waiting
    }

    // Key doesn't start any sequence - pass through immediately
    return .mismatched
  }

  /// Cancel any pending sequence detection and send buffered keys
  func cancel() {
    workItem?.cancel()
    workItem = nil

    if let code = pendingKeyCode {
      isSendingSyntheticKey = true
      KeySimulator.press(keyCode: code, modifiers: 0)
    }

    pendingSequence = ""
    pendingKeyCode = nil
    isSendingSyntheticKey = false
  }

  /// Check if we have a pending sequence waiting for second key
  var hasPendingSequence: Bool {
    return !pendingSequence.isEmpty && workItem != nil
  }
}
