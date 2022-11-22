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
            log("Error generating QR code")
            return
        }
        _ = image.pngWrite(to: Alfred.localDir/"qrcode.png")
    }

    static func generateQRCode(from content: String) -> NSImage? {
        let data = content.data(using: .utf8)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 30, y: 30)

            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                return nsImage
            }
        }
        return nil
    }
    
    /// 解析二唯图片里的内容
    static func decode(_ inputStr: String) {
        guard inputStr.fileExists else { return }
        guard let ciImage = CIImage(contentsOf: URL(fileURLWithPath: inputStr)) else { return }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
        let results = detector?.features(in: ciImage).compactMap({ ($0 as? CIQRCodeFeature)?.messageString?.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }) ?? []
        guard let item = results.first, !item.isEmpty else { return }
        print(item)
    }
}
