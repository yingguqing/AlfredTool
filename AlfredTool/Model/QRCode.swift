//
//  main.swift
//  QRCode
//
//  Created by zhouziyuan on 2022/3/29.
//

import Cocoa
import Foundation

class QRCode {
    static func run(_ inputStr: String) {
        guard !inputStr.isEmpty, let image = generateQRCode(from: inputStr) else {
            AlfredUtil.log("Error generating QR code")
            return
        }
        _ = image.pngWrite(to: AlfredUtil.local(filename: "qrcode.png"))
    }

    static func generateQRCode(from content: String) -> NSImage? {
        let data = content.data(using: .utf8)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                return nsImage
            }
        }
        return nil
    }
}
