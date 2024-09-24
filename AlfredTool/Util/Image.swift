//
//  Color.swift
//  Alfred
//
//  Created by zhouziyuan on 2022/3/27.
//

import AppKit
import Foundation

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to path: URL?, options: Data.WritingOptions = .atomic) throws -> Bool {
        guard let path, let pngData else { return false }
        try pngData.write(to: path, options: options)
        return true
    }

    /// 保存文件当前显示的icon
    class func saveFileIcon(filePath: String, savePath: String) throws -> Bool {
        let image = NSWorkspace.shared.icon(forFile: filePath)
        return try image.pngWrite(to: URL(fileURLWithPath: savePath))
    }
}
