//
//  FlatDecrypto.swift
//  FlatAESCrypto
//
//  Created by zhouziyuan on 2022/12/12.
//

import CommonCrypto
import Foundation

struct FlatAESCrypto {
    let aes: AES

    init(key: String, blockMode: BlockMode, padding: Padding) throws {
        self.aes = try AES(key: key.bytes, blockMode: blockMode, padding: padding)
    }

    func decrypt(_ data: Data) throws -> Data {
        let decryptedBytes = try aes.decrypt(data.bytes)
        return Data(decryptedBytes)
    }

    func decrypt(_ string: String) throws -> String? {
        guard let data = Data(base64Encoded: string.replacingOccurrences(of: "\n", with: "")) else { return nil }
        let deData = try decrypt(data)
        return String(data: deData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }

    static func decrypt(_ value: String) {}
}

extension CBC {
    init(iv: String) {
        self.init(iv: Data(iv.utf8).bytes)
    }
}

/// 解密信息
struct DecryptoInfo {
    /// 解密方法服务归属
    let name: String
    private let aes: FlatAESCrypto

    init(json: [String: String]) {
        guard let name = json["name"] else {
            print("缺少参数name，内容为解密方法服务归属。")
            exit(1)
        }
        self.name = name
        guard let mod = json["mod"]?.uppercased(), ["CBC", "ECB"].contains(mod) else {
            print("缺少参数mod，内容为解密模式。")
            exit(1)
        }
        guard let paddingString = json["padding"]?.lowercased(), ["0", "5", "7", "no"].contains(paddingString) else {
            print("\(name) 缺少参数padding，内容为解密Padding。")
            exit(1)
        }
        let iv = json["iv"] ?? ""
        let key = json["key"] ?? ""
        guard !key.isEmpty else {
            print("缺少解密key。")
            exit(1)
        }
        guard mod != "CBC" || !iv.isEmpty else {
            print("CBC模式，缺少解密iv。")
            exit(1)
        }
        let padding: Padding
        switch paddingString {
            case "0":
                padding = .zeroPadding
            case "5":
                padding = .pkcs5
            case "7":
                padding = .pkcs7
            default:
                padding = .noPadding
        }
        do {
            if mod == "CBC" {
                self.aes = try FlatAESCrypto(key: key, blockMode: CBC(iv: iv), padding: padding)
            } else {
                self.aes = try FlatAESCrypto(key: key, blockMode: ECB(), padding: padding)
            }
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    /// 对应的解密方法
    func flatDecrypt(value: String) -> String? {
        return try? aes.decrypt(value)
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
    func flatDecryptList() -> AlfredItem? {
        guard !self.isEmpty, let values:[[String: String]] = userConfig("Decrypto") else { return nil }
        // 具体的解密配置
        let infos = values.map({ DecryptoInfo(json: $0) })
        // 优先使用配置的解密方法
        for info in infos {
            guard let result = info.flatDecrypt(value: self) ?? info.flatDecrypt(value: self.urlDecode()) else { continue }
            var item = AlfredItem()
            item.uid = "1"
            item.subtitle = "Flat数据解密"
            item.arg = result.jsonFormat
            item.title = "\(info.name) • 解密成功"
            item.subtitle = result
            return item
        }
        // 再使用默认的解密方法
        guard let data = Data(base64Encoded: self) else { return nil }
        let contentData = data.subdata(in: 0 ..< (data.count-1))
        let keyData = data.subdata(in: (data.count-1) ..< (data.count))
        // 默认私钥
        guard let keyIndex = String(data: keyData, encoding: .utf8), let defaultKeyValue:[String: String] = userConfig("Default"), let key = defaultKeyValue[keyIndex], !key.isEmpty else { return nil }
        do {
            let aes = try FlatAESCrypto(key: key, blockMode: CBC(iv: key), padding: .zeroPadding)
            let dedata = try aes.decrypt(contentData)
            guard let result = String(data: dedata, encoding: .utf8), !result.isEmpty else { return nil }
            var item = AlfredItem()
            item.uid = "1"
            item.subtitle = "Flat数据解密"
            item.arg = result.jsonFormat
            item.title = "默认 • 解密成功"
            item.subtitle = result
            return item
        } catch {
            return nil
        }
    }
}

enum FlatDecrypto {

    static func decrypt(value:String, isPrint:Bool) {
        let dataString = value.curlRequestData.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\\/", with: "/")
        var item = AlfredItem()
        if let deItem = dataString.flatDecryptList() {
            item = deItem
        } else if value.isEmpty {
            item.title = "输入Flat的网络加密数据"
        } else {
            item.title = "解密失败"
        }
        if isPrint {
            print(item.arg)
        } else {
            Alfred.flush(item: item)
        }
    }
}
