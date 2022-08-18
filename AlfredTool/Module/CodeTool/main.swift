//
//  main.swift
//  CodeTool
//
//  Created by zhouziyuan on 2022/6/1.
//

import ArgumentParser
import Foundation

struct Repeat: ParsableCommand {
    @Option(help: "编码")
    var encode: String?
    @Option(help: "解码")
    var decode: String?

    func run() {
        if let encode = encode { // 编码工具
            DecodeEncodeTool.encode(encode)
        } else if let decode = decode { // 解码工具
            DecodeEncodeTool.decode(decode)
        }
    }
}

Repeat.main()
