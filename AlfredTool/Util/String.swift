//
//  String.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Cocoa

extension String {
    
    // 路径拼接
    static func /(parent: String, child: String) -> String {
        return (parent as NSString).appendingPathComponent(child)
    }
    
    var fileURL: URL {
        URL(fileURLWithPath: self)
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
    
    func pathRemove() {
        guard !self.isEmpty, self.fileExists else { return }
        do {
            try FileManager.default.removeItem(atPath: self)
        } catch let error as NSError {
            print("文件删除失败 \(error.localizedDescription)")
        }
    }
    
    /// 提取特定字符
    func stringByPreservingCharacters(_ preservedCharacters:String) -> String {
        let set = CharacterSet(charactersIn: preservedCharacters).inverted
        var stringArray = self.components(separatedBy: set)
        if stringArray.count != 1 {
            stringArray = stringArray.filter({ !$0.isEmpty })
        }
        return stringArray.joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 以特定字符分割
    func componentsSeparateByCharacters(_ preservedCharacters:String) -> [String] {
        let set = CharacterSet(charactersIn: preservedCharacters)
        let stringArray = self.components(separatedBy: set)
        guard stringArray.count != 1 else { return stringArray }
        return stringArray.filter({ !$0.isEmpty })
    }
    
    func urlEncode() -> String {
        var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: "!*'\"();:@&=+$,/?%#[]% ")
        return self.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey) ?? self
    }
    
    func urlDecode() -> String {
        return self.removingPercentEncoding ?? self
    }
    
    var base64Encode:String {
        return Data(self.utf8).base64EncodedString()
    }
    
    var base64Decode:String {
        guard let data = Data(base64Encoded: self) else { return self }
        return String(data: data, encoding: .utf8) ?? self
    }
    
    /// 如果是json字符串，就格式化一下，如果不是，就返回原字符串
    var jsonFormat:String {
        guard let json = try? JSONSerialization.jsonObject(with: Data(self.utf8), options: .allowFragments) else { return self }
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return self }
        return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/") ?? self
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
    
    /// 剪切板上的字符串
    static var clipboard:String? {
        NSPasteboard.general.string(forType: .string)
    }
    
    /// 把内容放到剪切板上
    @discardableResult func toClipboard() -> Bool {
        guard !self.isEmpty else { return false }
        NSPasteboard.general.setString(self, forType: .string)
        return NSPasteboard.general.string(forType: .string) == self
    }
}

extension String: CustomNSError {
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self]
    }
}
