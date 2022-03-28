//
//  Color.swift
//  Alfred
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation
import AppKit

extension NSImage {
    func save(path:String?) {
        guard let path = path, let data = self.tiffRepresentation else {
            return
        }
        let representation = NSBitmapImageRep(data: data)
        let saveData = representation?.representation(using: .png, properties: [.compressionFactor: 1])
        try? saveData?.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
}
