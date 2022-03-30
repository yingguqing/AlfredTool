//
//  StringTool.swift
//  EncodeDecode
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

class StringTool {
    
    static func encode(_ value:String) {
        let icon = AlfredUtil.itemIcon(title: "Encode")
        let urlItem = AlfredItem()
        urlItem.icon = icon
        urlItem.uid = "1"
        urlItem.arg = "url \(value.urlEncode())"
        urlItem.title = value.urlEncode()
        urlItem.subtitle = "URL Encoded"
        
        let base64Item = AlfredItem()
        base64Item.icon = icon
        base64Item.uid = "2"
        base64Item.arg = "base64 \(value.base64Encode)"
        base64Item.title = value.base64Encode
        base64Item.subtitle = "Base64 Encoded"
        
        Alfred.flush(alfredItem: urlItem, base64Item)
    }
    
    static func decode(_ value:String) {
        let icon = AlfredUtil.itemIcon(title: "Decode")
        let urlItem = AlfredItem()
        urlItem.icon = icon
        urlItem.uid = "1"
        urlItem.arg = "url \(value.urlDecode())"
        urlItem.title = value.urlDecode()
        urlItem.subtitle = "URL Decoded"
        
        let base64Item = AlfredItem()
        base64Item.icon = icon
        base64Item.uid = "2"
        base64Item.arg = "base64 \(value.base64Decode)"
        base64Item.title = value.base64Decode
        base64Item.subtitle = "Base64 Decoded"
        
        Alfred.flush(alfredItem: urlItem, base64Item)
    }
    
    static func check(_ value:String) {
        guard !value.isEmpty else { return }
        let target = ["url ", "base64 "]
        target.forEach {
            guard value.hasPrefix($0) else { return }
            print(String(value.dropFirst($0.count)))
        }
    }
}

extension String {
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
}
