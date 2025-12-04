import AppKit
import SwiftUI

@MainActor
struct AccessibilityPermissionCallout: View {
    @ObservedObject var permissions: AccessibilityPermissionManager
    var compactButtons: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility needed to paste")
                        .font(.callout.weight(.semibold))
                    Text(
                        "Enable Trimmy in System Settings → Privacy & Security → Accessibility so ⌘V can be sent to the front app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }

            HStack(spacing: 10) {
                Button("Grant Accessibility") {
                    self.permissions.requestPermissionPrompt()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(self.compactButtons ? .small : .regular)

                Button("Open Settings") {
                    self.permissions.openSystemSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(self.compactButtons ? .small : .regular)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)))
    }
}
