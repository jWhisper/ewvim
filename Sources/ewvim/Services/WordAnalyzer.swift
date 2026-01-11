import Foundation

enum MovementDirection {
  case left
  case right
}

struct WordAnalyzer {
  // 单词字符: 字母 [a-zA-Z]、数字 [0-9]、下划线 _
  static func isWordChar(_ c: Character) -> Bool {
    c.isLetter || c.isNumber || c == "_"
  }

  // 空白字符: 空格、制表符
  static func isWhitespace(_ c: Character) -> Bool {
    c == " " || c == "\t"
  }

  // w: 移动到下一个单词的首字符（跳过空白）
  static func findNextWordStart(from cursor: Int, in text: String) -> Int? {
    let chars = Array(text)
    guard cursor < chars.count else { return nil }

    // 从 cursor 开始找
    var i = cursor

    // 如果当前在空白字符上，先跳过空白
    while i < chars.count && isWhitespace(chars[i]) {
      i += 1
    }

    if i >= chars.count { return nil }

    // 如果当前在单词字符上，先跳过当前单词
    let onWordChar = isWordChar(chars[i])
    while i < chars.count {
      let c = chars[i]
      if onWordChar {
        if !isWordChar(c) { break }
      } else {
        if isWhitespace(c) { break }
      }
      i += 1
    }

    // 跳过空白到下一个单词
    while i < chars.count && isWhitespace(chars[i]) {
      i += 1
    }

    return i < chars.count ? i : nil
  }

  // b: 移动到上一个单词的首字符
  static func findPreviousWordStart(from cursor: Int, in text: String) -> Int? {
    let chars = Array(text)
    guard cursor > 0 else { return nil }

    var i = cursor > 0 ? cursor - 1 : 0

    // 跳过空白
    while i >= 0 && isWhitespace(chars[i]) {
      guard i > 0 else { return nil }
      i -= 1
    }

    if i < 0 { return nil }

    // 确定当前字符类型
    let onWordChar = isWordChar(chars[i])

    // 跳过单词或非单词字符
    while i >= 0 {
      let c = chars[i]
      if onWordChar {
        if !isWordChar(c) {
          i += 1  // 当前字符是目标
          break
        }
      } else {
        if isWhitespace(c) {
          i += 1
          break
        }
      }
      guard i > 0 else { break }
      i -= 1
    }

    // 如果 i < 0，说明到了字符串开头，返回 0 if valid
    if i < 0 {
      i = 0
      // 检查开头是否是有效字符
      while i < chars.count && isWhitespace(chars[i]) {
        i += 1
      }
    } else if isWhitespace(chars[i]) {
      // 如果停在了空白上，跳过
      i += 1
    }

    return i < chars.count && i != cursor ? i : nil
  }

  // e: 移动到当前/下一个单词的尾字符（不包括标点）
  // Vim 的 e 行为：如果在单词尾字符上，移动到下一个单词尾
  static func findCurrentOrNextWordEnd(from cursor: Int, in text: String) -> Int? {
    let chars = Array(text)
    guard cursor < chars.count else {
      print("         ❌ findCurrentOrNextWordEnd: cursor=\(cursor) >= chars.count=\(chars.count)")
      return nil
    }

    var i = cursor

    // 如果当前在空白字符上，先跳过空白
    while i < chars.count && isWhitespace(chars[i]) {
      print("         🔁 Skipping whitespace at \(i): '\(chars[i])'")
      i += 1
    }

    if i >= chars.count {
      print("         ❌ Reached end after skipping whitespace")
      return nil
    }

    print("         📍 Current char at \(i): '\(chars[i])', isWord=\(isWordChar(chars[i]))")

    // 确定当前字符类型
    let onWordChar = isWordChar(chars[i])

    if !onWordChar {
      print("         ⚠️ Not on word char, skipping non-word chars")
      // 跳过当前非单词字符（标点等）
      while i < chars.count {
        let c = chars[i]
        if isWhitespace(c) { break }
        print("         🔁 Skipping non-word char at \(i): '\(c)'")
        i += 1
      }
      // 跳过空白到下一个单词
      while i < chars.count && isWhitespace(chars[i]) {
        print("         🔁 Skipping whitespace to next word")
        i += 1
      }
      if i >= chars.count { return nil }
      print("         📍 Now at word start at \(i): '\(chars[i])'")
    } else {
      // 在单词字符上，先尝试找当前单词的结尾
      var endPos = i
      var j = i
      while j < chars.count && isWordChar(chars[j]) {
        endPos = j
        print("         🔁 Word char at \(j): '\(chars[j])', endPos=\(endPos)")
        j += 1
      }

      // 如果当前已经在单词尾字符上（endPos == cursor），找下一个单词
      if endPos == cursor {
        print("         ⚠️ Already at word end, finding next word end")
        // 跳过非单词字符
        while j < chars.count {
          let c = chars[j]
          if isWhitespace(c) { break }
          print("         🔁 Skipping non-word char at \(j): '\(c)'")
          j += 1
        }
        // 跳过空白到下一个单词
        while j < chars.count && isWhitespace(chars[j]) {
          print("         🔁 Skipping whitespace to next word")
          j += 1
        }
        if j >= chars.count { return nil }
        print("         📍 Found next word start at \(j): '\(chars[j])'")
        // 现在在下一个单词上，找它的结尾
        i = j
      } else {
        print("         ✅ Found word end inside current word")
        return endPos
      }
    }

    // 找单词结尾（最后一个单词字符）
    var endPos = i
    while i < chars.count && isWordChar(chars[i]) {
      endPos = i
      print("         🔁 Word char at \(i): '\(chars[i])', endPos=\(endPos)")
      i += 1
    }

    let result = endPos > cursor ? endPos : nil
    print("         ✅ findCurrentOrNextWordEnd: cursor=\(cursor) -> result=\(String(describing: result))")
    return result
  }
}

struct MovementCalculator {
  static func calculateArrowKeysToMove(from: Int, to: Int) -> (arrowCount: Int, direction: MovementDirection) {
    if to >= from {
      return (arrowCount: to - from, direction: .right)
    } else {
      return (arrowCount: from - to, direction: .left)
    }
  }
}
