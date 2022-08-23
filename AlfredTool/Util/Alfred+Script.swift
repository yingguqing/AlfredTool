//
//  Alfred+Scrypt.swift
//  FlatAESCrypto
//
//  Created by zhouziyuan on 2022/8/23.
//

import Foundation

extension Alfred {
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
