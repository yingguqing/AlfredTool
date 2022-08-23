import Foundation

enum Alfred {
    private static let fs: FileManager = .default
    // 用户主目录
    static let home: URL = fs.homeDirectoryForCurrentUser
    // Alfred 4 app所在目录
    static let appBundlePath: URL = .init(fileURLWithPath: "/Applications/Alfred 4.app")
    // 是否安装Alfred 4
    static let isInstalled: Bool = fs.exists(appBundlePath)
    // Alfred 的Application Support目录
    static let appSupportDir: URL = home/"Library"/"Application Support"/"Alfred"
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
}
