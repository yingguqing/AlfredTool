//
//  main.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/6/1.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    @Flag(help: "检查结果")
    var check = false
    @Option(help: "时间戳")
    var timestamp: String?

    func run() {
        if let timestamp = timestamp { // 时间戳工具
            if check {
                guard !timestamp.isEmpty else { Repeat.exit(withError: nil) }
                if timestamp.lowercased().hasPrefix("save ") {
                    Timestamp.save(dateFormats: String(timestamp.dropFirst(5)))
                } else {
                    print(timestamp)
                }
            } else {
                if timestamp.lowercased().hasPrefix("add ") {
                    Timestamp.add(dateFormat: String(timestamp.dropFirst(4)))
                } else if timestamp.lowercased().hasPrefix("remove ") {
                    Timestamp.remove(dateFormat: String(timestamp.dropFirst(7)))
                } else {
                    Timestamp.run(timestamp)
                }
            }
        }
    }
}

Repeat.main()
