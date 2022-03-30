//
//  Color.swift
//  Alfred
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation
import AppKit

class ColorTool {
    var color:NSColor?
    
    /// 调起颜色选择器
    /// - Parameter title: 标题
    func fallbackToColorPanelResult(_ title:String="OS X Color Panel") {
        let uid = AlfredUtil.bundleID.appending(" color-pick")
        let item = AlfredItem()
        item.uid = uid
        item.icon = "pick-color.png"
        item.title = title
        item.subtitle = "Action this item to open the OS X color panel"
        Alfred.flush(alfredItem: item)
    }
    
    func input(_ value:String) -> Bool {
        var query = value
        if query.hasPrefix("#") || query.hasPrefix("0x") {
            if query.hasPrefix("0x") {
                query = String(query.dropFirst(2))
            }
            query = query.stringByPreservingCharacters("0123456789abcdefABCDEF")
            guard !query.isEmpty || query.count > 8 else { return true }
            var color:NSColor?
            while query.count <= 8, color == nil {
                color = NSColor(query)
                if query.count > 6 {
                    query.append("F")
                } else {
                    query.append("0")
                }
            }
            guard let color = color else { return true }
            self.color = color
        } else if query.hasPrefix("rgb") {
            let divisor:CGFloat = query.contains("%") ? 100 : 255
            query = query.stringByPreservingCharacters("0123456789., ")
            guard !query.isEmpty || query.count > 8 else { return true }
            let queryArray = query.componentsSeparateByCharacters(", ").map({ CGFloat(Double($0) ?? 0) / divisor })
            let r = queryArray.value(index: 0) ?? 0
            let g = queryArray.value(index: 1) ?? 0
            let b = queryArray.value(index: 2) ?? 0
            let a = queryArray.value(index: 3) ?? 1
            self.color = NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
        } else { 
            return true
        }
        
        return false
    }
    
    func feedback() {
        guard let color = color else {
            Alfred.flush(alfredItems: [])
            return
        }
        let image = color.toImage()
        let path = AlfredUtil.cache(filename: color.hexadecimal + ".png")
        _ = image.pngWrite(to: path)
        
        var items = [AlfredItem]()
        
        let rgb = AlfredItem()
        rgb.uid = "RGB"
        rgb.autocomplete = String(format: "(%.f, %.f, %.f)", color.redComponent * 255, color.greenComponent * 255, color.blueComponent * 255)
        rgb.arg = "rgb\(rgb.autocomplete)"
        rgb.title = rgb.arg
        rgb.subtitle = "RGB"
        rgb.icon = path ?? ""
        
        let hex = AlfredItem()
        hex.uid = "Hex"
        hex.autocomplete = color.hexadecimal
        hex.arg = hex.autocomplete
        hex.title = hex.arg
        hex.subtitle = "Hexadecimal"
        hex.icon = path ?? ""
        
        items.append(rgb)
        items.append(hex)
        
        if color.alphaComponent != 1 {
            let rgba = AlfredItem()
            rgba.uid = "RGB • Alpha"
            rgba.autocomplete = String(format: "(%.f, %.f, %.f, %.f)", color.redComponent * 255, color.greenComponent * 255, color.blueComponent * 255, color.alphaComponent)
            rgba.arg = "rgb\(rgb.autocomplete)"
            rgba.title = rgb.arg
            rgba.subtitle = "RGBA"
            rgba.icon = path ?? ""
            
            let hexa = AlfredItem()
            hexa.uid = "Hex • Alpha"
            hexa.autocomplete = color.hexadecimal
            hexa.arg = hex.autocomplete
            hexa.title = hexa.arg
            hexa.subtitle = "Hexadecimal"
            hexa.icon = path ?? ""
            
            items.append(rgba)
            items.append(hexa)
        }
        
        Alfred.flush(alfredItems: items)
    }
    
    func openColorPanel() {
        let input:String
        if let color = color {
            input = String(format: "%f %f %f %f", color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
        } else {
            input = ""
        }
        let panel = Process()
        panel.launchPath = "Colors.app/Contents/MacOS/Colors"
        panel.arguments = [input]
        panel.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        panel.standardOutput = pipe
        panel.launch()
        panel.waitUntilExit()
        let pipeFile = pipe.fileHandleForReading
        let data = pipeFile.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8)
        guard let out = out, !out.isEmpty else { return }
        let array = out.components(separatedBy: " ").map({ Int(round((Double($0) ?? 0) * 0xFF)) })
        let r = array.value(index: 0) ?? 0
        let g = array.value(index: 1) ?? 0
        let b = array.value(index: 2) ?? 0
        let a = array.value(index: 3) ?? 1
        let value = String(format: "#%.8X", r * 256 * 256 * 256 + g * 256 * 256 + b * 256 + a)
        Alfred.sendToAlfred(value)
    }
}


