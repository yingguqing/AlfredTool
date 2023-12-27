//
//  main.swift
//  DistinctProvisionProfile
//
//  Created by zhouziyuan on 2022/8/25.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    @Flag(help: "删除重复描述文件")
    var distinct:Bool = false
    
    func run() {
        guard distinct else { return }
        DistinctProvisionProfile().run()
    }
}

Repeat.main()

