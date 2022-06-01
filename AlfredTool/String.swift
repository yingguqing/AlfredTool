//
//  String.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation

extension String {
    
    // 路径拼接
    static func /(parent: String, child: String) -> String {
        return (parent as NSString).appendingPathComponent(child)
    }
    
    func stringByPreservingCharacters(_ preservedCharacters:String) -> String {
        let set = CharacterSet(charactersIn: preservedCharacters).inverted
        var stringArray = self.components(separatedBy: set)
        if stringArray.count != 1 {
            stringArray = stringArray.filter({ !$0.isEmpty })
        }
        return stringArray.joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
        return String(data: data, encoding: .utf8) ?? self
    }
}
