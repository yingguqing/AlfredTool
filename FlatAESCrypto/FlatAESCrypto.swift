//
//  FlatAESCrypto.swift
//  FlatSDK
//
//  Created by zhouziyuan on 2022/3/11.
//

import CommonCrypto
import Foundation

struct FlatAESCrypto {
    let keyIndex: String // 加密key的索引
    private let key: Data
    private let iv: Data
    private let options: CCOptions = .init(kCCOptionPKCS7Padding)

    init(keyIndex: String? = nil) throws {
        guard let privateValue = userConfig("FlatPrivateKeyValue") as? [String:String] else {
            throw Error.invalidKeySize
        }
        // 加密时，不需要传索引，会自动随机一个索引来做为加密的key
        let index = keyIndex ?? privateValue.randomElement()?.key
        guard let index = index, let iv = privateValue[index] else {
            throw Error.invalidKeySize
        }
        guard iv.count == kCCKeySizeAES128 || iv.count == kCCKeySizeAES256 else {
            throw Error.invalidKeySize
        }
        guard let ivData = iv.data(using: .utf8) else {
            throw Error.invalidKeySize
        }
        self.keyIndex = index
        self.key = ivData
        self.iv = ivData
    }

    func encrypt(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        return try crypt(data, option: CCOperation(kCCEncrypt))
    }

    func decrypt(_ data: Data) throws -> Data {
        return try crypt(data, option: CCOperation(kCCDecrypt))
    }

    static func decryptPay(data: String) -> String {
        guard !data.isEmpty else { return data }
        guard let contentData = Data(base64Encoded: data) else { return "不是base64字符串" }
        do {
            let aes = try FlatAESCrypto(keyIndex: "a")
            let data = try aes.decrypt(contentData)
            return String(data: data, encoding: .utf8) ?? "解密失败"
        } catch {
            return error.localizedDescription
        }
    }

    static func decrypt(_ value: String) {
        let dataString = value.curlRequestData.replacingOccurrences(of: "\n", with: "")
        var item = AlfredItem()
        item.uid = "1"
        item.subtitle = "Flat数据解密"
        if value.isEmpty {
            item.arg = value
            item.title = "输入Flat的网络加密数据"
        } else if let decrypt = dataString.flatPayDecrypt?.trimmingCharacters(in: CharacterSet.controlCharacters) {
            item.arg = decrypt.jsonFormat
            item.title = "解密成功"
        } else if let decrypt = dataString.flatDecrypt?.trimmingCharacters(in: CharacterSet.controlCharacters) {
            item.arg = decrypt.jsonFormat
            item.title = "解密成功"
        } else {
            item.arg = ""
            item.title = "解密失败"
        }

        Alfred.flush(item: item)
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

private extension FlatAESCrypto {
    private func crypt(_ data: Data, option: CCOperation) throws -> Data {
        let dataLength = size_t(data.count)
        var buffer = Data(count: dataLength + Int(kCCBlockSizeAES128))
        let bufferLength = size_t(buffer.count)
        var bytesDecrypted: size_t = 0

        do {
            try self.key.withUnsafeBytes { keyBytes in
                try iv.withUnsafeBytes { ivBytes in
                    try data.withUnsafeBytes { dataToEncryptBytes in
                        try buffer.withUnsafeMutableBytes { bufferBytes in

                            guard let keyBytesBaseAddress = keyBytes.baseAddress,
                                  let ivBytesBaseAddress = ivBytes.baseAddress,
                                  let dataToEncryptBytesBaseAddress = dataToEncryptBytes.baseAddress,
                                  let bufferBytesBaseAddress = bufferBytes.baseAddress
                            else {
                                throw Error.encryptionFailed
                            }
                            let cryptStatus: CCCryptorStatus = CCCrypt(
                                option,
                                CCAlgorithm(kCCAlgorithmAES),
                                options,
                                keyBytesBaseAddress,
                                key.count,
                                ivBytesBaseAddress,
                                dataToEncryptBytesBaseAddress,
                                dataToEncryptBytes.count,
                                bufferBytesBaseAddress,
                                bufferLength,
                                &bytesDecrypted
                            )

                            guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                                throw Error.encryptionFailed
                            }
                        }
                    }
                }
            }

        } catch {
            throw Error.encryptionFailed
        }
        buffer.count = bytesDecrypted
        return buffer
    }
}

private extension String {
    /// 从curl中提取data
    var curlRequestData: String {
        guard self.hasPrefix("curl ") else { return self }
        let parser = CurlParser(command: self)
        let result = parser.parse()
        guard let postData = result.postData else { return self }
        let header = "request_data="
        guard let requestDataString = postData.components(separatedBy: "&").filter({ $0.hasPrefix(header) }).first else {
            return self
        }
        return String(requestDataString.dropFirst(header.count)).urlDecode()
    }

    /// 字符串加密
    var flatEncrypt: String? {
        do {
            let aes = try FlatAESCrypto()
            let keyData = Data(aes.keyIndex.utf8)
            var data = try aes.encrypt(self)
            data.append(keyData)
            return data.base64EncodedString()
        } catch {
            return nil
        }
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
        guard let contentData = Data(base64Encoded: self) else {
            return nil
        }
        do {
            let aes = try FlatAESCrypto(keyIndex: "a")
            let data = try aes.decrypt(contentData)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
