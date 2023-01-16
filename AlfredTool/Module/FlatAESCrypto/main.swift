//
//  main.swift
//  FlatAESCrypto
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser


struct Repeat: ParsableCommand {
    
    @Flag(help: "flat数据解密")
    var decrypt:Bool = false
    
    func run() {
        if decrypt {
            FlatDecrypto.decrypt()
        }
    }
}

Repeat.main()

