import Foundation

enum Alfred {
    private static let fs: FileManager = .default
    // 用户主目录
    private static let home: URL = fs.homeDirectoryForCurrentUser
    // Alfred 4 app所在目录
    static let appBundlePath: URL = .init(fileURLWithPath: "/Applications/Alfred 4.app")
    // 是否安装Alfred 4
    static let isInstalled: Bool = fs.exists(appBundlePath)
    // Alfred 4的info.plist
    private static let alfredPlist: Plist = .init(path: appBundlePath/"Contents"/"Info.plist")
    // Alfred 4的版本号
    static let build: Int = .init(alfredPlist.get("CFBundleVersion", orElse: "0"))!
    // Alfred 4的bundle id
    static let bundleID: String = alfredPlist.get("CFBundleIdentifier", orElse: "com.runningwithcrayons.Alfred")
    // Alfred 的Application Support目录
    static let appSupportDir: URL = home/"Library"/"Application Support"/"Alfred"
    // Alfred的缓存目录
    static let cacheDir: URL = home/"Library"/"Caches"/bundleID
    // workflow所在的目录
    static let localDir: URL = Bundle.main.bundleURL
}

extension Alfred {
    /// 回调内容给Alfred
    /// - Parameters:
    ///   - alfredItems: 显示item项
    ///   - isExit: 是否结束命令
    static func flush(items: [AlfredItem], isExit: Bool = true) {
        print(items.toJsonString())
        guard isExit else { return }
        exit(EX_USAGE)
    }

    /// 回调内容给Alfred
    /// - Parameters:
    ///   - alfredItem: 显示item项
    ///   - isExit: 是否结束命令
    static func flush(item: AlfredItem..., isExit: Bool = true) {
        flush(items: item, isExit: isExit)
    }

    /// 通过bundle id把内容发送到Alfred里
    /// - Parameters:
    ///   - content: 内容
    static func sendToAlfred(_ content: String, bundleId: String? = nil) {
        let source = """
        tell application id "com.runningwithcrayons.Alfred" to run trigger "feedback" in workflow "\(bundleId ?? Alfred.bundleID)" with argument "\(content)"
        """
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(nil)
    }
}
