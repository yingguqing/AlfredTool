//
//  main.swift
//  SearchOpen
//
//  Created by zhouziyuan on 2022/7/27.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    
    @Option(help: "查询组")
    var group: String?
    @Option(help: "查询内容")
    var input: String?
    
    func run() {
        guard let group = group else { return }
        SearchOpen.searchFile(group: group, input: input ?? "")
    }
}

Repeat.main()
