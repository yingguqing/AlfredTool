//
//  main.swift
//  AlfredTool
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation
import ArgumentParser

/*
 ./AlfredTool --
 --color                颜色
 --check                输出结果 (default: false)
 --output               输出结果,不做任何处理
 --open-color-panel     打开颜色选择器 (default: false)
 --timestamp            时间戳
 --qr-code              二维码
 --encoode              编码
 --decoode              解码
 --flat-decrypt         flat数据解密
 */

struct Repeat: ParsableCommand {
    
    @Option(help: "颜色")
    var color: String?
    @Flag(help: "检查结果")
    var check = false
    @Option(help: "输出结果,不做任何处理")
    var output: String?
    @Flag(help: "打开颜色选择器")
    var openColorPanel = false
    @Option(help: "时间戳")
    var timestamp: String?
    @Option(help: "二维码")
    var qrCode: String?
    @Option(help: "编码")
    var encode: String?
    @Option(help: "解码")
    var decode: String?
    @Option(help: "flat数据解密")
    var flatDecrypt: String?
    
    func run() {
        
        if let output = output {// 输出结果
            print(output)
        } else if let color = color {// 颜色工具
            let colorTool = ColorTool()
            if check {
                if color.isEmpty {
                    colorTool.openColorPanel()
                } else {
                    print(color)
                }
            } else if openColorPanel {
                _ = colorTool.input(color)
                colorTool.openColorPanel()
            } else {
                let prefixes = ["#", "rgb", "rgba", "ns", "ui"]
                if prefixes.contains(color) {
                    colorTool.fallbackToColorPanelResult()
                }
                if colorTool.input(color) {
                    colorTool.fallbackToColorPanelResult("No Results")
                }
                colorTool.feedback()
            }
        } else if let timestamp = timestamp { // 时间戳工具
            if check {
                guard !timestamp.isEmpty else { Repeat.exit(withError: nil) }
                if timestamp.lowercased().hasPrefix("save ") {
                    Timestamp.save(dateFormats: String(timestamp.dropFirst(5)))
                } else {
                    print(timestamp)
                }
            } else {
                if timestamp.lowercased().hasPrefix("add ") {
                    Timestamp.add(dateFormat: String(timestamp.dropFirst(4)))
                } else if timestamp.lowercased().hasPrefix("remove ") {
                    Timestamp.remove(dateFormat: String(timestamp.dropFirst(7)))
                } else {
                    Timestamp.run(timestamp)
                }
            }
        } else if let qrCode = qrCode { // 生成二维码
            QRCode.run(qrCode)
        } else if let encode = encode { // 编码工具
            DecodeEncodeTool.encode(encode)
        } else if let decode = decode { // 解码工具
            DecodeEncodeTool.decode(decode)
        } else if let flatDecrypt = flatDecrypt {// flat sdk 数据解密
            FlatAESCrypto.decrypt(flatDecrypt)
        }
    }
}

Repeat.main()


