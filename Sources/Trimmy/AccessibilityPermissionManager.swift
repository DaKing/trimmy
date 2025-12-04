import AppKit
import ApplicationServices
import Foundation

@MainActor
protocol AccessibilityPermissionChecking: AnyObject {
    var isTrusted: Bool { get }
}

@MainActor
protocol AccessibilityPermissionHandling: AccessibilityPermissionChecking, ObservableObject {
    func requestPermissionPrompt()
    func openSystemSettings()
    func refresh()
}

/// Minimal helper for querying and requesting Accessibility permission.
@MainActor
final class AccessibilityPermissionManager: AccessibilityPermissionHandling {
    @Published private(set) var isTrusted: Bool

    private var pollTask: Task<Void, Never>?
    private let pollInterval: TimeInterval

    init(pollInterval: TimeInterval = 2.0) {
        self.isTrusted = AXIsProcessTrusted()
        self.pollInterval = pollInterval
        self.startPolling()
    }

    nonisolated deinit {
        self.pollTask?.cancel()
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != self.isTrusted {
            self.isTrusted = trusted
        }
    }

    func requestPermissionPrompt() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options)
        // Opening System Settings helps when the dialog is suppressed or the user dismissed it earlier.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.openSystemSettings()
        }
        self.scheduleRefresh()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func startPolling() {
        self.pollTask?.cancel()
        self.pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let delay = UInt64(self.pollInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                self.refresh()
            }
        }
    }

    private func scheduleRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refresh()
        }
    }
}
