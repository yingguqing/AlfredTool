//
//  Data.swift
//  AlfredTool
//  
//  Created by 影孤清 on 2025/6/23.
//  
    
import Foundation
import CommonCrypto
import CryptoKit

extension Data {
    var bytes: [UInt8] {
        Array(self)
    }
    
    /// 异或数据
    ///
    /// - Parameter keyData: 异或所用的key
    /// - Returns: 异或后的数据
    func xor(key: Data) -> Data {
        let keyBytes = key.bytes
        let keyCount = keyBytes.count
        let bytes = self.bytes.enumerated().map({ $1 ^ keyBytes[$0 % keyCount] })
        return Data(bytes: bytes, count: self.count)
    }
    
    /// data异或成base64字符串
    /// - Parameter key: 异或所用的key
    /// - Returns: 异或后的base64
    func xor(key: String) -> String {
        guard !self.isEmpty else { return "" }
        let keyData = key.data
        let enData = self.xor(key: keyData)
        return enData.base64EncodedString()
    }
    
    var toHexString: String {
        lazy.reduce(into: "") { $0 += String(format: "%02x", $1) }
    }
    
    var sha1: Data {
        let hash = Insecure.SHA1.hash(data: self)
        return Data(hash)
    }
    
    /// AES,CBC(key),PKCS7 加密方法
    func encrypt(key: String) throws -> Data {
        return try self.crypt(key: key, operation: CCOperation(kCCEncrypt))
    }

    /// AES,CBC(key),PKCS7 解密方法
    func decrypt(key: String) throws -> Data {
        return try self.crypt(key: key, operation: CCOperation(kCCDecrypt))
    }

    private func crypt(key: String, operation: CCOperation) throws -> Data {
        guard key.count == kCCKeySizeAES128 else {
            throw "Error: Key length must be 16 characters (128 bits)."
        }

        let keyData = key.data
        let ivData = key.data

        let dataLength = count
        let cryptLength = dataLength + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted = 0

        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            self.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    ivData.withUnsafeBytes { ivBytes in
                        CCCrypt(operation,
                                CCAlgorithm(kCCAlgorithmAES128),
                                CCOptions(kCCOptionPKCS7Padding),
                                keyBytes.baseAddress!, kCCKeySizeAES128,
                                ivBytes.baseAddress!,
                                dataBytes.baseAddress!, dataLength,
                                cryptBytes.baseAddress!, cryptLength,
                                &numBytesEncrypted)
                    }
                }
            }
        }
        guard cryptStatus == kCCSuccess else {
            throw "Error: Failed to perform crypt operation. Status: \(cryptStatus)"
        }
        cryptData.removeSubrange(numBytesEncrypted ..< cryptData.count)
        return cryptData
    }
    
    func jsonObject<T>(options opt: JSONSerialization.ReadingOptions = []) throws -> T {
        let value = try JSONSerialization.jsonObject(with: self, options: opt)
        guard let result = value as? T else { throw "数据解析json转换失败" }
        return result
    }
}

