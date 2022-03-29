//
//  main.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

// 命令的所有参数
let queryOption = StringOption(shortFlag: "q", longFlag: "query", required: true, helpMessage: "Query value.")
// 以下参数互斥
let check = BoolOption(shortFlag: "c", longFlag: "check", helpMessage: "check")

// 解析命令
Alfred.readLine(queryOption, check)

let query = queryOption.value ?? ""

if check.value {
    guard !query.isEmpty else { exit(EX_USAGE) }
    print(query)
} else {
    Timestamp.run(query)
}
