//
//  Crypto.swift
//  CommandLine
//
//  Created by 影孤清A on 2023/10/17.
//

import CryptoKit
import Foundation

extension String {
    /// 字符串的MD5
    var md5: String {
        return Insecure.MD5.hash(data: Data(self.utf8)).map({ String(format: "%02X", $0) }).joined()
    }

    /// 文件的MD5
    var fileMD5: String? {
        guard let data = try? Data(contentsOf: self.fileURL), !data.isEmpty else { return nil }
        return Insecure.MD5.hash(data: data).map({ String(format: "%02X", $0) }).joined()
    }

    var sha256: String {
        var sha256 = SHA256()
        sha256.update(data: Data(self.utf8))
        return sha256.finalize().map({ String(format: "%02X", $0) }).joined()
    }
}
