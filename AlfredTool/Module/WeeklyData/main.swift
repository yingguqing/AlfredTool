//
//  main.swift
//  WeeklyData
//
//  Created by zhouziyuan on 2022/7/20.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    
    @Flag(help: "插入周报")
    var insert:Bool = false
    
    @Option(help: "内容")
    var input: String?
    
    @Option(help: "插入日期")
    var date:String?
    
    @Flag(help: "查看周报")
    var check:Bool = false
    
    @Flag(help: "导出一周周报")
    var export:Bool = false
    
    func run() {
        guard let input = input?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        if insert {
            WeeklyDataManager.insert(report: input, date: date)
        } else if check {
            WeeklyDataManager.weeklyDataList(query: input)
        } else if export {
            WeeklyDataManager.export(input)
        }
    }
}

Repeat.main()

