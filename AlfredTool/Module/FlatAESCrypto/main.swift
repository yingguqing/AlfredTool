//
//  main.swift
//  FlatAESCrypto
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser


struct Repeat: ParsableCommand {
    
    @Flag(help: "flat数据解密－剪切板")
    var decrypt:Bool = false
    
    @Flag(help: "flat数据加密－剪切板")
    var encrypt:Bool = false
    
    @Option(help: "flat数据解密特定内容")
    var decryptValue:String?
    
    func run() {
        if let decryptValue = decryptValue {
            FlatDecrypto.decrypt(value: decryptValue, isPrint: true)
        } else if decrypt {
            let pasteboard = String.clipboard ?? ""
            FlatDecrypto.decrypt(value: pasteboard, isPrint: false)
        } else if encrypt {
            let pasteboard = String.clipboard ?? ""
            FlatDecrypto.encrypt(value: pasteboard)
        }
    }
}

Repeat.main()

