//
//  main.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

// 命令的所有参数
let queryOption = StringOption(shortFlag: "q", longFlag: "query", helpMessage: "Query value.")
// 以下参数互斥
let check = BoolOption(shortFlag: "c", longFlag: "check", helpMessage: "check")

// 解析命令
Alfred.readLine(queryOption, check)

let query = queryOption.value?.trimmingCharacters(in: .whitespaces) ?? ""
if check.value {
    guard !query.isEmpty else { exit(EX_USAGE) }
    if query.lowercased().hasPrefix("save ") {
        Timestamp.save(dateFormats: String(query.dropFirst(5)))
    } else {
        print(query)
    }
} else {
    if query.lowercased().hasPrefix("add ") {
        Timestamp.add(dateFormat: String(query.dropFirst(4)))
    } else if query.lowercased().hasPrefix("remove ") {
        Timestamp.remove(dateFormat: String(query.dropFirst(7)))
    } else {
        Timestamp.run(query)
    }
}
