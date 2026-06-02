import Foundation

enum Alfred {
    // 用户主目录
    static let home: URL = FileManager.default.homeDirectoryForCurrentUser
    // Alfred 的Application Support目录
    static let appSupportDir: URL = home / "Library/Application Support/Alfred"
    // workflow所在的目录
    //static let localDir: URL = Bundle.main.bundleURL
    static let localDir: URL = URL(fileURLWithPath: "/Users/yuan/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/user.workflow.BED49B45-6F48-4E1D-B712-F7FED16D84BB")
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
