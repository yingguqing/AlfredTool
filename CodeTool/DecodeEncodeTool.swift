//
//  StringTool.swift
//  EncodeDecode
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

class DecodeEncodeTool {
    
    static func encode(_ value:String) {
        var urlItem = AlfredItem()
        urlItem.uid = "1"
        urlItem.arg = value.urlEncode()
        urlItem.title = urlItem.arg
        urlItem.subtitle = "URL Encoded"
        
        var base64Item = AlfredItem()
        base64Item.uid = "2"
        base64Item.arg = value.base64Encode
        base64Item.title = base64Item.arg
        base64Item.subtitle = "Base64 Encoded"
        
        Alfred.flush(item: urlItem, base64Item)
    }
    
    static func decode(_ value:String) {
        var urlItem = AlfredItem()
        urlItem.uid = "1"
        urlItem.arg = value.urlDecode()
        urlItem.title = urlItem.arg
        urlItem.subtitle = "URL Decoded"
        
        var base64Item = AlfredItem()
        base64Item.uid = "3"
        base64Item.arg = value.base64Decode
        base64Item.title = base64Item.arg
        base64Item.subtitle = "Base64 Decoded"
        
        Alfred.flush(item: urlItem, base64Item)
    }
}
