//
//  main.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation

// 命令的所有参数
let queryOption = StringOption(shortFlag: "q", longFlag: "query", required: true, helpMessage: "Query value.")
// 以下参数互斥
let check = BoolOption(shortFlag: "c", longFlag: "check", helpMessage: "check")
let reveal = BoolOption(shortFlag: "r", longFlag: "reveal", helpMessage: "reveal")

// 解析命令
Alfred.readLine(queryOption, check, reveal)

let query = queryOption.value ?? ""

let colors = Colors()
if check.value {
    if query.isEmpty {
        colors.openColorPanel()
    } else {
        print(query)
    }
} else if reveal.value {
    _ = colors.input(query)
    colors.openColorPanel()
} else {
    let prefixes = ["#", "rgb", "rgba", "ns", "ui"]
    if prefixes.contains(query) {
        colors.fallbackToColorPanelResult()
    }
    if colors.input(query) {
        colors.fallbackToColorPanelResult("No Results")
    }
    colors.feedback()
}




