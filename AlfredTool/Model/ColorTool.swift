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
        let item = AlfredItem.item(title: title,
                                   subtitle: "Action this item to open the OS X color panel",
                                   icon: .fromImage(at: URL(fileURLWithPath: "pick-color.png")))
        Alfred.flush(item: item)
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
            Alfred.flush(items: [])
            return
        }
        let image = color.toImage()
        let path = Alfred.cacheDir/(color.hexadecimal + ".png")
        _ = image.pngWrite(to: path)
        let icon = AlfredItem.Icon.fromImage(at: path)
        var items = [AlfredItem]()
        
        if color.alphaComponent != 1 {
            var arg = String(format: "rgb(%.f, %.f, %.f, %.f)", color.redComponent * 255, color.greenComponent * 255, color.blueComponent * 255, color.alphaComponent)
            let rgba = AlfredItem.item(arg: arg,
                                       title: arg,
                                       subtitle: "RGBA",
                                       autocomplete: arg,
                                       icon: icon)
            
            

            arg = color.hexadecimal
            let hexa = AlfredItem.item(arg: arg,
                        title: arg,
                        subtitle: "Hexadecimal",
                        autocomplete: arg,
                        icon: icon)
            
            items.append(rgba)
            items.append(hexa)
        } else {
            var arg = String(format: "rgb(%.f, %.f, %.f)", color.redComponent * 255, color.greenComponent * 255, color.blueComponent * 255)
            let rgb = AlfredItem.item(arg: arg,
                                      title: arg,
                                      subtitle: "RGB",
                                      autocomplete: arg,
                                      icon: icon)
            
            arg = color.hexadecimal
            let hex = AlfredItem.item(arg: arg,
                                      title: arg,
                                      subtitle: "Hexadecimal",
                                      autocomplete: arg,
                                      icon: icon)
            
            items.append(rgb)
            items.append(hex)
        }
        
        Alfred.flush(items: items)
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


