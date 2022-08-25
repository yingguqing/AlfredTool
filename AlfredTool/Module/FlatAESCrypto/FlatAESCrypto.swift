//
//  FlatAESCrypto.swift
//  FlatSDK
//
//  Created by zhouziyuan on 2022/3/11.
//

import CommonCrypto
import Foundation

struct FlatAESCrypto {
    let aes: AES

    init(keyIndex: String? = nil, padding: Padding = .zeroPadding) throws {
        // 密钥保存在配置文件中
        guard let privateValue = userConfig("FlatPrivateKeyValue") as? [String: String] else {
            throw Error.invalidKeySize
        }
        guard let index = keyIndex, let iv = privateValue[index] else {
            throw Error.invalidKeySize
        }
        self.aes = try AES(key: iv, iv: iv, padding: padding)
    }

    init(key: String, blockMode: BlockMode = ECB(), padding: Padding = .pkcs7) throws {
        self.aes = try AES(key: key.bytes, blockMode: blockMode, padding: padding)
    }

    func decrypt(_ data: Data) throws -> Data {
        let decryptedBytes = try aes.decrypt(data.bytes)
        return Data(decryptedBytes)
    }

    func decrypt(_ string:String) throws -> String? {
        guard let data = Data(base64Encoded: string) else { return nil }
        let deData = try decrypt(data)
        return String(data: deData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
    
    static func decrypt(_ value: String) {
        let dataString = value.curlRequestData.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\\/", with: "/")
        var item = AlfredItem()
        item.uid = "1"
        item.subtitle = "Flat数据解密"
        if value.isEmpty {
            item.arg = value
            item.title = "输入Flat的网络加密数据"
        } else if let decrypt = dataString.flatDecryptList {
            item.arg = decrypt.1.jsonFormat
            item.title = decrypt.0
        } else {
            item.arg = ""
            item.title = "解密失败"
        }

        Alfred.flush(item: item)
    }
}

public extension CBC {
    init(iv: String) {
        self.init(iv: Data(iv.utf8).bytes)
    }
}

private extension FlatAESCrypto {
    enum Error: Swift.Error {
        case invalidKeySize
        case encryptionFailed
        case decryptionFailed
        case dataToStringFailed
    }
}

private extension String {
    /// 从curl中提取data
    var curlRequestData: String {
        if self.hasPrefix("curl ") {
            let parser = CurlParser(command: self)
            let result = parser.parse()
            guard let postData = result.postData else { return self }
            let header = "request_data="
            guard let requestDataString = postData.components(separatedBy: "&").filter({ $0.hasPrefix(header) }).first else {
                return self
            }
            return String(requestDataString.dropFirst(header.count)).urlDecode()
        } else if self.hasPrefix("http") {
            let array = self.components(separatedBy: "chat?p=")
            // 如果包含，表示是客服请求参数
            if array.count == 2 {
                return array[1].urlDecode()
            }
        }
        return self
    }

    /// 字符串解密
    var flatDecrypt: String? {
        guard !self.isEmpty else {
            return nil
        }
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        let contentData = data.subdata(in: 0 ..< (data.count-1))
        let keyData = data.subdata(in: (data.count-1) ..< (data.count))
        do {
            let aes = try FlatAESCrypto(keyIndex: String(data: keyData, encoding: .utf8))
            let data = try aes.decrypt(contentData)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// 支付数据解密
    var flatPayDecrypt: String? {
        guard !self.isEmpty else {
            return nil
        }
        do {
            let aes = try FlatAESCrypto(keyIndex: "a")
            return try aes.decrypt(self)
        } catch {
            return nil
        }
    }

    /// 客服请求数据解密
    var flatCustomerDecrypt: String? {
        guard let dic = userConfig("FlatCustomerKeyIv") as? [String: String], let key = dic["key"], let iv = dic["iv"] else { return nil }
        do {
            let aes = try FlatAESCrypto(key: key, blockMode: CBC(iv: iv))
            return try aes.decrypt(self)
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    /// 归因接口
    var flatGameCenterDecrypt: String? {
        guard let key = userConfig("FlatGameCenterKey") as? String else { return nil }
        do {
            let aes = try FlatAESCrypto(key: key)
            return try aes.decrypt(self)
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}

private extension String {
    /// 所有解密方式都解一遍
    var flatDecryptList: (String, String)? {
        let item = [
            ("支付数据解密成功", self.flatPayDecrypt),
            ("客服数据解密成功", self.flatCustomerDecrypt),
            ("用户中心解密成功", self.flatGameCenterDecrypt),
            ("网络数据解密成功", self.flatDecrypt)
        ].filter({ $0.1 != nil }).first
        guard let item = item else { return nil }
        return (item.0, item.1!)
    }
}
