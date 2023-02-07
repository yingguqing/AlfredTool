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

    func encrypt(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        let encryptedBytes = try aes.encrypt(data.bytes)
        return Data(encryptedBytes)
    }

    func decrypt(_ string: String) throws -> String? {
        guard let data = Data(base64Encoded: string.replacingOccurrences(of: "\n", with: "")) else { return nil }
        let deData = try decrypt(data)
        return String(data: deData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
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
    /// 默认加解密参数的索引
    let indexKey: String
    /// 是否为默认加解密参数
    var isDefault: Bool

    private let aes: FlatAESCrypto

    init(json: [String: String], key:String) {
        self.name = json["name"] ?? key
        self.indexKey = key
        self.isDefault = json["isDefault"] == "1"
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

    /// 所有解密参数集 isOnlyOneDefault:表示随机保留一个默认解密集，用于加密
    static func all(isOnlyOneDefault: Bool = false) -> [DecryptoInfo] {
        let values:[String:[String:String]] = userConfig() ?? [:]
        var infos = values.map({ DecryptoInfo(json: $0.1, key: $0.0) })
        if isOnlyOneDefault, let item = infos.filter({  $0.isDefault }).randomElement() {
            infos = infos.filter({ !$0.isDefault }) + [item]
        }
        return infos
    }

    /// 对应的解密方法
    func flatDecrypt(value: String) -> String? {
        if isDefault {
            guard let data = Data(base64Encoded: value) else { return nil }
            let contentData = data.subdata(in: 0 ..< (data.count-1))
            let keyData = data.subdata(in: (data.count-1) ..< (data.count))
            guard let index = String(data: keyData, encoding: .utf8), indexKey == index, let dedata = try? aes.decrypt(contentData) else { return nil }
            guard let result = String(data: dedata, encoding: .utf8), !result.isEmpty else { return nil }
            return result
        } else {
            return try? aes.decrypt(value)
        }
    }

    /// 对应的加密方法
    func flatEncrypt(value: String) -> String? {
        if isDefault {
            var data = try? aes.encrypt(value)
            data?.append(Data(indexKey.utf8))
            return data?.base64EncodedString()
        } else {
            return try? aes.encrypt(value).base64EncodedString()
        }
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
        // 具体的解密配置
        let infos = DecryptoInfo.all(isOnlyOneDefault: false)
        guard !self.isEmpty, !infos.isEmpty else { return nil }
        let urlDecode = self.urlDecode()
        // 优先使用配置的解密方法
        for info in infos {
            guard let result = info.flatDecrypt(value: self) ?? info.flatDecrypt(value: urlDecode) else { continue }
            var item = AlfredItem()
            item.subtitle = "Flat数据解密"
            item.arg = result.jsonFormat
            item.title = "\(info.name) • 解密"
            item.subtitle = result
            return item
        }
        return nil
    }
    
    /// 所有加密都加一遍，默认就只随机使用一个
    func flatEncryptList() -> [AlfredItem] {
        // 具体的解密配置
        let infos = DecryptoInfo.all(isOnlyOneDefault: true)
        guard !self.isEmpty, !infos.isEmpty else { return [] }
        // 优先使用配置的解密方法
        return infos.compactMap({
            guard let result = $0.flatEncrypt(value: self) else { return nil }
            var item = AlfredItem()
            item.uid = $0.name
            item.subtitle = "Flat数据加密"
            item.arg = result
            item.subtitle = result
            item.title = "\($0.name) • 加密"
            return item
        })
    }
}

enum FlatDecrypto {
    static func decrypt(value: String, isPrint: Bool) {
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

    /// 加密内容
    /// - Parameters:
    ///   - value: 需要加密的内容
    ///   - name: 指定加密参数的名字，只能是配置文件中有的
    static func encrypt(value: String) {
        let items = value.flatEncryptList()
        if !items.isEmpty {
            Alfred.flush(items: items)
        } else if value.isEmpty {
            Alfred.flush(item: .item(title: "输入准备加密的内容"))
        } else {
            Alfred.flush(item: .item(title: "加密失败"))
        }
    }
}
