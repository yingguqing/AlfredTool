//
//  main.swift
//  ColorTool
//
//  Created by zhouziyuan on 2022/6/1.
//

import ArgumentParser
import Foundation

struct Repeat: ParsableCommand {
    @Option(help: "颜色")
    var color: String?
    @Flag(help: "检查结果")
    var check = false
    @Flag(help: "打开颜色选择器")
    var openColorPanel = false

    func run() {
        if let color = color { // 颜色工具
            let colorTool = ColorTool()
            if check {
                if color.isEmpty {
                    colorTool.openColorPanel()
                } else {
                    print(color)
                }
            } else if openColorPanel {
                _ = colorTool.input(color)
                colorTool.openColorPanel()
            } else {
                let prefixes = ["#", "rgb", "rgba", "ns", "ui"]
                if prefixes.contains(color) {
                    colorTool.fallbackToColorPanelResult()
                }
                if colorTool.input(color) {
                    colorTool.fallbackToColorPanelResult("No Results")
                }
                colorTool.feedback()
            }
        }
    }
}

Repeat.main()
