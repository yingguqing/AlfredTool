//
//  main.swift
//  EncodeDecode
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

// 命令的所有参数
let queryOption = StringOption(shortFlag: "q", longFlag: "query", helpMessage: "Query value.")
// 以下参数互斥
let check = BoolOption(shortFlag: "c", longFlag: "check", helpMessage: "check")
let isEncode = BoolOption(shortFlag: "e", longFlag: "encode", helpMessage: "encode")
let isDecode = BoolOption(shortFlag: "d", longFlag: "decode", helpMessage: "decode")


// 解析命令
Alfred.readLine(queryOption, check, isEncode, isDecode)

let query = queryOption.value?.trimmingCharacters(in: .whitespaces) ?? ""

if isEncode.value {
    StringTool.encode(query)
} else if isDecode.value {
    StringTool.decode(query)
} else if check.value {
    StringTool.check(query)
} else {
    exit(EX_USAGE)
}
