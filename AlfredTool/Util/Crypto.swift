//
//  Crypto.swift
//  CommandLine
//
//  Created by 影孤清A on 2023/10/17.
//

import CommonCrypto
import CryptoKit
import Foundation
import zlib

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = [UInt8](key.utf8)
        let cData = [UInt8](self.utf8)
        var result = [UInt8](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey, cKey.count, cData, cData.count, &result)
        let hmacData = NSData(bytes: result, length: Int(algorithm.digestLength()))
        let hmacBase64 = hmacData.base64EncodedString(options: .lineLength76Characters)
        return String(hmacBase64)
    }

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

    var crc32Int: UInt {
        guard let data = self.data(using: .utf8) else { return 0 }
        let checksum = data.withUnsafeBytes {
            zlib.crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt(data.count))
        }
        return UInt(checksum)
    }

    var crc32: String {
        let checksum = self.crc32Int
        guard checksum > 0 else { return self }
        return String(checksum)
    }
}

enum HMACAlgorithm {
    case MD5
    case SHA1
    case SHA224
    case SHA256
    case SHA384
    case SHA512

    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
