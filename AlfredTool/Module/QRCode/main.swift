//
//  main.swift
//  QRCode
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser

/*
 --qr-code <qr-code>     二维码
 --ipa-server-qr-code <ipa-server-qr-code>
                         ipa安装地址
 --qr-code-file-path <qr-code-file-path>
                         二维码图片地址
 -h, --help              Show help information.
 */
struct Repeat: ParsableCommand {
    
    @Option(help: "二维码")
    var qrCode: String?
    
    @Option(help: "ipa安装地址")
    var ipaServerQrCode:String?
    
    @Option(help: "二维码图片地址")
    var qrCodeFilePath: String?
    
    func run() {
        if let qrCode = qrCode { // 生成二维码
            QRCode.run(qrCode)
        } else if let qrCode = ipaServerQrCode {
            QRCode.run("itms-services://?action=download-manifest&url="+qrCode)
        } else if let qrCodeFilePath = qrCodeFilePath {
            QRCode.decode(qrCodeFilePath)
        }
    }
}

Repeat.main()




