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

    func decrypt(_ string: String) throws -> String? {
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
            item.arg = decrypt.jsonFormat
            item.title = "解密成功"
            item.subtitle = decrypt
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

    /// 所有解密方式都解一遍
    var flatDecryptList: String? {
        let item = DecryptType.allCases.compactMap({ $0.flatDecodeDecrypt(value: self) }).filter({ !$0.isEmpty })
        return item.first
    }
}

///  所有解密方法
enum DecryptType: String, CaseIterable {
    case Pay
    case Customer
    case GameCenter
    case Network

    /// 解码解密，优先直接解，如果解不了，尝试urldecode后再解密
    func flatDecodeDecrypt(value: String) -> String? {
        return flatDecrypt(value: value) ?? flatDecrypt(value: value.urlDecode())
    }

    /// 对应的解密方法
    func flatDecrypt(value: String) -> String? {
        guard !value.isEmpty else { return nil }
        do {
            switch self {
                case .Pay:
                    let aes = try FlatAESCrypto(keyIndex: "a")
                    return try aes.decrypt(value)
                case .Customer:
                    guard let dic = userConfig("FlatCustomerKeyIv") as? [String: String], let key = dic["key"], let iv = dic["iv"] else { return nil }
                    let aes = try FlatAESCrypto(key: key, blockMode: CBC(iv: iv))
                    return try aes.decrypt(value)
                case .GameCenter:
                    guard let key = userConfig("FlatGameCenterKey") as? String else { return nil }
                    let aes = try FlatAESCrypto(key: key)
                    return try aes.decrypt(value)
                case .Network:
                    guard let data = Data(base64Encoded: value) else { return nil }
                    let contentData = data.subdata(in: 0 ..< (data.count-1))
                    let keyData = data.subdata(in: (data.count-1) ..< (data.count))
                    let aes = try FlatAESCrypto(keyIndex: String(data: keyData, encoding: .utf8))
                    let dedata = try aes.decrypt(contentData)
                    return String(data: dedata, encoding: .utf8)
            }
        } catch {
            return nil
        }
    }
}
