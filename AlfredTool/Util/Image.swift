//
//  Color.swift
//  Alfred
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation
import AppKit

extension NSImage {
    
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to path: URL?, options: Data.WritingOptions = .atomic) -> Bool {
        guard let path = path else { return false }
        do {
            try pngData?.write(to:path, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
