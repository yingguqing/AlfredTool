//
//  String.swift
//  ComposeSDKTool
//
//  Created by 影孤清 on 2019/7/29.
//  Copyright © 2019 影孤清. All rights reserved.
//

import Cocoa
import CommonCrypto
import zlib

extension String {
    public func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
        else { return nil }
        return from..<to
    }
    
    // Range转换为NSRange
    func range(from range: Range<String.Index>) -> NSRange {
        let startPos = self.distance(from: self.startIndex, to: range.lowerBound)
        let endPos = self.distance(from: self.startIndex, to: range.upperBound)
        return NSMakeRange(startPos, endPos - startPos)
    }
    
    // 路径拼接 "/a/b" / "c.mp3" = "/a/b/c.mp3"
    static func /(parent: String, child: String) -> String {
        return (parent as NSString).appendingPathComponent(child)
    }
    
    // 字符串乘法。比如 .*2=..
    static func *(parent: String, child: Int) -> String {
        if child < 0 {
            return parent
        } else if child == 0 {
            return ""
        } else {
            let array = [String](repeating: parent, count: child)
            return array.joined()
        }
    }
    
    /// 获得文件的扩展类型（不带'.'）
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
    /// 从路径中获得完整的文件名（带后缀）
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    /// 删除最后一个/后面的内容 可以是整个文件名,可以是文件夹名
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    
    /// 获得文件名（不带后缀）
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    
    /// 删除后缀的文件名
    var fileNameWithoutExtension: String {
        return self.lastPathComponent.deletingPathExtension
    }
    
    /// 文件是否存在
    var fileExists: Bool {
        guard !self.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: self)
    }
    
    /// 目录是否存在，非目录时，返回false
    var directoryExists: Bool {
        guard !self.isEmpty else { return false }
        var isDirectory = ObjCBool(booleanLiteral: false)
        let isExists = FileManager.default.fileExists(atPath: self, isDirectory: &isDirectory)
        return isDirectory.boolValue && isExists
    }
    
    // 生成目录所有文件
    @discardableResult func createFilePath(isDelOldPath: Bool = false) -> String {
        guard !self.isEmpty else { return self }
        do {
            if isDelOldPath, self.fileExists {
                self.pathRemove()
            } else if self.fileExists {
                return self
            }
            try FileManager.default.createDirectory(atPath: self, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("创建目录失败 \(error.localizedDescription)")
        }
        return self
    }
    
    /// 字符串写成文件，可以提升权限
    ///
    /// - Parameters:
    ///   - path: 写成文件路径
    ///   - permissions: 是否提升权限到777
    func write(toFile path: String, permissions: Bool = false) throws {
        if path.fileExists {
            path.pathRemove()
        }
        try self.write(toFile: path, atomically: true, encoding: .utf8)
        guard permissions else { return }
        // 将文件的权限设为777,可执行
        let atributes = [FileAttributeKey.posixPermissions: 0o777]
        try FileManager.default.setAttributes(atributes, ofItemAtPath: path)
    }
    
    func pathRemove() {
        guard !self.isEmpty, self.fileExists else { return }
        do {
            try FileManager.default.removeItem(atPath: self)
        } catch let error as NSError {
            print("文件删除失败 \(error.localizedDescription)")
        }
    }
    
    var base64Encoding: String {
        guard self.isEmpty == false else { return "" }
        if let plainData = self.data(using: .utf8) {
            let base64String = plainData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            return base64String
        }
        return ""
    }
    
    var base64Decoding: String {
        guard self.isEmpty == false else { return "" }
        if let decodedData = Data(base64Encoded: self),
           let decodedString = String(data: decodedData, encoding: .utf8)
        {
            return decodedString
        }
        return ""
    }
    
    private func validIndex(original: Int) -> String.Index {
        switch original {
        case ...startIndex.utf16Offset(in: self): return startIndex
        case endIndex.utf16Offset(in: self)...: return endIndex
        default: return index(startIndex, offsetBy: original)
        }
    }
    
    private func validStartIndex(original: Int) -> String.Index? {
        guard original <= endIndex.utf16Offset(in: self) else { return nil }
        return self.validIndex(original: original)
    }
    
    private func validEndIndex(original: Int) -> String.Index? {
        guard original >= startIndex.utf16Offset(in: self) else { return nil }
        return self.validIndex(original: original)
    }
    
    subscript(_ range: CountableRange<Int>) -> String {
        guard
            let startIndex = validStartIndex(original: range.lowerBound),
            let endIndex = validEndIndex(original: range.upperBound),
            startIndex < endIndex
        else {
            return ""
        }
        return String(self[startIndex..<endIndex])
    }
    
    static let random_str_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static func randomString(_ len: Int, includeNum: Bool = false) -> String {
        let randomString = includeNum ? self.random_str_characters + "1234567890" : self.random_str_characters
        var ranStr = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(randomString.count)))
            ranStr.append(randomString[randomString.index(randomString.startIndex, offsetBy: index)])
        }
        return ranStr
    }
    
    /// 补空格
    func addSpaceTo(_ count: Int) -> String {
        guard count > self.count else { return self }
        var result = self
        while result.count < count {
            result += " "
        }
        return result
    }
    
    // 将原始的url编码为合法的url
    var urlEncoded: String {
        let custom = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters: custom)
        return encodeUrlString ?? ""
    }
    
    // 将编码后的url转换回原始的url
    var urlDecoded: String {
        return self.removingPercentEncoding ?? ""
    }
    
    var chineseInitials: String {
        if let str1 = self.applyingTransform(StringTransform.toLatin, reverse: false) {
            if let str2 = str1.applyingTransform(StringTransform.stripCombiningMarks, reverse: false) {
                let pinyin = str2.capitalized
                var headPinyinStr = ""
                // 获取所有大写字母
                for ch in pinyin {
                    if ch <= "Z", ch >= "A" {
                        headPinyinStr.append(ch)
                    }
                }
                return headPinyinStr
            }
        }
        return ""
    }
    
    var toDictionary: [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        let dic = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
        return dic
    }
    
}
