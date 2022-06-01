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
    
    func run() {
        if let qrCode = qrCode { // 生成二维码
            QRCode.run(qrCode)
        }
    }
}

Repeat.main()




