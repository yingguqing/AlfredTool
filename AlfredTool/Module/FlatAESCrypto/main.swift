//
//  main.swift
//  FlatAESCrypto
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser


struct Repeat: ParsableCommand {
    
    @Option(help: "flat数据解密")
    var flatDecrypt: String?
    
    func run() {
        if let flatDecrypt = flatDecrypt {// flat sdk 数据解密
            FlatDecrypto.decrypt(flatDecrypt)
        }
    }
}

Repeat.main()

