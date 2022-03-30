//
//  StringTool.swift
//  EncodeDecode
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

class DecodeEncodeTool {
    
    static func encode(_ value:String) {
        let icon = AlfredUtil.itemIcon(title: "Encode")
        let urlItem = AlfredItem()
        urlItem.icon = icon
        urlItem.uid = "1"
        urlItem.arg = value.urlEncode()
        urlItem.title = urlItem.arg
        urlItem.subtitle = "URL Encoded"
        
        let base64Item = AlfredItem()
        base64Item.icon = icon
        base64Item.uid = "2"
        base64Item.arg = value.base64Encode
        base64Item.title = base64Item.arg
        base64Item.subtitle = "Base64 Encoded"
        
        Alfred.flush(alfredItem: urlItem, base64Item)
    }
    
    static func decode(_ value:String) {
        let icon = AlfredUtil.itemIcon(title: "Decode")
        let urlItem = AlfredItem()
        urlItem.icon = icon
        urlItem.uid = "1"
        urlItem.arg = value.urlDecode()
        urlItem.title = urlItem.arg
        urlItem.subtitle = "URL Decoded"
        
        let base64Item = AlfredItem()
        base64Item.icon = icon
        base64Item.uid = "2"
        base64Item.arg = value.base64Decode
        base64Item.title = base64Item.arg
        base64Item.subtitle = "Base64 Decoded"
        
        Alfred.flush(alfredItem: urlItem, base64Item)
    }
}
