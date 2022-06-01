//
//  Color.swift
//  Alfred
//
//  Created by zhouziyuan on 2022/3/27.
//

import AppKit
import Foundation

extension NSColor {
    func toImage(size: CGSize = CGSize(width: 128, height: 128)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        self.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }

    /// 十六进制字符串形式
    convenience init?(_ hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 4:
            (r, g, b, a) = ((int >> 12) * 17, (int >> 8 & 0xF) * 17, (int >> 4 & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(r: r, g: g, b: b, a: a)
    }

    convenience init(r: UInt64, g: UInt64, b: UInt64, a: UInt64) {
        self.init(calibratedRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
    
    convenience init(r: Int, g: Int, b: Int, a: Double) {
        self.init(calibratedRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: a)
    }
    
    var hexadecimal:String {
        var red:CGFloat = 0
        var green:CGFloat = 0
        var blue:CGFloat = 0
        var alpha:CGFloat = 0
        let multiplier = CGFloat(255.999999)
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        if alpha == 1 {
            return String(format: "%02lX%02lX%02lX", Int(red * multiplier), Int(green * multiplier), Int(blue * multiplier))
        } else {
            return String(format: "%02lX%02lX%02lX%02lX", Int(red * multiplier), Int(green * multiplier), Int(blue * multiplier), Int(alpha * multiplier) )
        }
    }
}


