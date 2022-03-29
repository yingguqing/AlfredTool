//
//  main.swift
//  QRCode
//
//  Created by zhouziyuan on 2022/3/29.
//

import Cocoa
import Foundation

class QRCode {
    static func run() {
        guard let inputStr = CommandLine.arguments.dropFirst().first, !inputStr.isEmpty,
              let image = generateQRCode(from: inputStr)
        else {
            AlfredUtil.log("Error generating QR code")
            return
        }
        let savePath = URL(fileURLWithPath: AlfredUtil.local(filename: "qrcode.png"))
        save(image: image, to: savePath)
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

    static func save(image: NSImage, to path: URL) {
        _ = image.pngWrite(to: path)
    }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

QRCode.run()
