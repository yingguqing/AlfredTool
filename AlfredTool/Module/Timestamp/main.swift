//
//  main.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    @Option(help: "输入内容")
    var input: String?
    @Flag(help: "新增格式前")
    var addBefore = false
    @Flag(help: "新增格式")
    var add = false
    @Flag(help: "删除格式")
    var del = false
    @Flag(help: "格式列表")
    var list = false

    func run() {
        guard let input = input else { return }
        
        if addBefore {
            Timestamp.addBefore(input)
        } else if add {
            Timestamp.save(dateFormats: input, isAdd: true)
        } else if del, !input.isEmpty {
            Timestamp.save(dateFormats: input, isAdd: false)
        } else if list {
            Timestamp.formatList(del)
        } else {
            Timestamp.run(input)
        }
    }
}

Repeat.main()
