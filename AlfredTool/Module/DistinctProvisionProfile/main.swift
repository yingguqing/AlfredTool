//
//  main.swift
//  DistinctProvisionProfile
//
//  Created by zhouziyuan on 2022/8/25.
//

import Foundation
import ArgumentParser
import AppKit

struct Repeat: ParsableCommand {
    @Flag(help: "删除重复描述文件")
    var distinct:Bool = false
/*
    @Option(help: "查询组")
    var group: String?
    @Option(help: "查询内容")
    var input: String?
*/
    
    func run() {
        guard distinct else { return }
        DistinctProvisionProfile().run()
    }
}

Repeat.main()

