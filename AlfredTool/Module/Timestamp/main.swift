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
    
    @Option(help: "日期格式")
    var format: String?

    func run() {
        guard let input = input else { return }
        
        let formats = format?.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines )}).filter({ !$0.isEmpty }) ?? []
        
        Timestamp.run(input, formats: formats)
    }
}

Repeat.main()
