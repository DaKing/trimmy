import Foundation

enum InstallOrigin {
    static func isHomebrewCask(appBundleURL: URL) -> Bool {
        let path = appBundleURL.path
        return path.contains("/Caskroom/") || path.contains("/Homebrew/Caskroom/")
    }
}
