//
//  AlfredItem.swift
//  AlfredWorkflow
//
//  Created by zhouziyuan on 2022/3/26.
//

import Foundation

public class AlfredItem {
    public var uid: String = "" // 结果以uid排序
    public var arg: String = "" // 往后传递的参数
    public var autocomplete: String = ""
    public var title: String = ""
    public var icon: String = ""
    public var subtitle: String = ""
    
    public init() {
        
    }
}


extension AlfredItem {

    var xmlNode : XMLNode {
        /*
         <item uid="1"
         arg="Brand spanking new process - Google Docs"
         autocomplete="Brand spanking new process - Google Docs">
         <icon>/Applications/Safari.app/Contents/Resources/compass.icns</icon>
         <title>Brand spanking new process - Google Docs</title>
         <subtitle> Process: Safari | App name: Safari.app</subtitle>
         </item>
         */
        let element = XMLElement(name: "item")
        
        element.addAttribute(XMLNode.attribute(withName: "uid", stringValue: self.uid) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: "arg", stringValue: self.arg) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: "autocomplete", stringValue: self.autocomplete) as! XMLNode)
        
        let titleElement = XMLElement(name: "title")
        titleElement.addChild(XMLNode.text(withStringValue: self.title) as! XMLNode)
        element.addChild(titleElement)
        
        let iconElement = XMLElement(name: "icon")
        iconElement.addChild(XMLNode.text(withStringValue: self.icon) as! XMLNode)
        element.addChild(iconElement)
        
        let subtitleElement = XMLElement(name: "subtitle")
        subtitleElement.addChild(XMLNode.text(withStringValue: self.subtitle) as! XMLNode)
        element.addChild(subtitleElement)
        
        return element
    }
}



extension Array where Element == AlfredItem {
    
    var xml: XMLDocument {
        let root = XMLElement(name: "items")
        root.setChildren(self.map({ $0.xmlNode }))
        return XMLDocument(rootElement: root)
    }
}

