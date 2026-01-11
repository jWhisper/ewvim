import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = VimViewModel()

  var body: some View {
    VStack(spacing: 0) {
      // Status Bar
      HStack {
        ModeIndicator(mode: viewModel.mode)
        Spacer()
        if !viewModel.currentCommand.isEmpty {
          Text(viewModel.currentCommand)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
        }
      }
      .padding(12)
      .background(Color.black)
      .foregroundColor(.white)

      // Main Content
      VStack(spacing: 20) {
        Image(systemName: "keyboard")
          .font(.system(size: 60))
          .foregroundColor(.primary)

        Text("ewvim")
          .font(.system(size: 32, weight: .bold))
          .foregroundColor(.primary)

        Text("Vim mode everywhere on macOS")
          .font(.system(size: 16))
          .foregroundColor(.secondary)

        if viewModel.accessibilityEnabled {
          HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
            Text("Accessibility enabled")
              .font(.system(.caption))
              .foregroundColor(.secondary)
          }
          .padding(.top, 10)
        } else {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text("Accessibility not enabled")
              .font(.system(.caption))
              .foregroundColor(.secondary)
          }
          .padding(.top, 10)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    }
    .onAppear {
      viewModel.requestAccessibility()
    }
  }
}

struct ModeIndicator: View {
  let mode: VimMode

  var body: some View {
    Text(mode.rawValue.uppercased())
      .font(.system(.headline, design: .monospaced))
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(modeColor)
      .cornerRadius(6)
  }

  var modeColor: Color {
    switch mode {
    case .normal: return Color.blue
    case .insert: return Color.red
    case .visual: return Color.yellow
    case .command: return Color.purple
    }
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif