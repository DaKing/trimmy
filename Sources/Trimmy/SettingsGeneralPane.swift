import AppKit
import SwiftUI

@MainActor
struct GeneralSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: AccessibilityPermissionManager
    @State private var isInstallingCLI = false
    @State private var cliStatus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !self.permissions.isTrusted {
                AccessibilityPermissionCallout(permissions: self.permissions)
            }
            PreferenceToggleRow(
                title: "Auto-trim enabled",
                subtitle: "Automatically trim clipboard content when it looks like a command.",
                binding: self.$settings.autoTrimEnabled)

            PreferenceToggleRow(
                title: "Keep blank lines",
                subtitle: "Preserve intentional blank lines instead of collapsing them.",
                binding: self.$settings.preserveBlankLines)

            PreferenceToggleRow(
                title: "Remove box drawing chars (│┃)",
                subtitle: "Strip prompt-style box gutters (any count, leading/trailing) before trimming.",
                binding: self.$settings.removeBoxDrawing)

            PreferenceToggleRow(
                title: "Use extra clipboard fallbacks",
                subtitle: "Try RTF and public text types when plain text is missing.",
                binding: self.$settings.usePasteboardFallbacks)

            #if DEBUG
            PreferenceToggleRow(
                title: "Enable debug tools",
                subtitle: "Show the Debug tab for sample previews and dev-only controls.",
                binding: self.$settings.debugPaneEnabled)
            #endif

            self.cliInstallerSection

            Divider()
                .padding(.vertical, 4)

            PreferenceToggleRow(
                title: "Start at Login",
                subtitle: "Automatically opens the app when you start your Mac.",
                binding: self.$settings.launchAtLogin)

            HStack {
                Spacer()
                Button("Quit Trimmy") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private var cliInstallerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    Task { await self.installCLI() }
                } label: {
                    if self.isInstallingCLI {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Install CLI")
                    }
                }
                .disabled(self.isInstallingCLI)

                if let status = self.cliStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Text("Install `trimmy` into /usr/local/bin and /opt/homebrew/bin.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - CLI installer

    private func installCLI() async {
        guard !self.isInstallingCLI else { return }
        self.isInstallingCLI = true
        defer { self.isInstallingCLI = false }

        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("TrimmyCLI")

        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            await MainActor.run { self.cliStatus = "Helper missing; reinstall Trimmy." }
            return
        }

        let installScript = """
        #!/usr/bin/env bash
        set -euo pipefail
        HELPER=\"\(helperURL.path)\"
        TARGETS=("/usr/local/bin/trimmy" "/opt/homebrew/bin/trimmy")

        for t in "${TARGETS[@]}"; do
          mkdir -p "$(dirname "$t")"
          ln -sf "$HELPER" "$t"
          echo "Linked $t -> $HELPER"
        done
        """

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("install_trimmy_cli.sh")

        do {
            defer { try? FileManager.default.removeItem(at: scriptURL) }
            try installScript.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let escapedPath = scriptURL.path.replacingOccurrences(of: "\"", with: "\\\"")
            let appleScript = "do shell script \"bash \\\"\(escapedPath)\\\"\" with administrator privileges"

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript]
            let stderrPipe = Pipe()
            process.standardError = stderrPipe

            try process.run()
            process.waitUntilExit()
            let status: String
            if process.terminationStatus == 0 {
                status = "Installed. Try: trimmy --help"
            } else {
                let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let msg = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                status = "Failed: \(msg ?? "error")"
            }
            await MainActor.run { self.cliStatus = status }
        } catch {
            await MainActor.run { self.cliStatus = "Failed: \(error.localizedDescription)" }
        }
    }
}
