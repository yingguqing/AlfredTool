//
//  main.swift
//  QRCode
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    
    @Option(help: "二维码")
    var qrCode: String?
    
    @Option(help: "ipa安装地址")
    var ipaServerQrCode:String?
    
    func run() {
        if let qrCode = qrCode { // 生成二维码
            QRCode.run(qrCode)
        } else if let qrCode = ipaServerQrCode {
            QRCode.run("itms-services://?action=download-manifest&url="+qrCode)
        }
    }
}

Repeat.main()




