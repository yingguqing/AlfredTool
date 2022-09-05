//
//  main.swift
//  WeeklyData
//
//  Created by zhouziyuan on 2022/7/20.
//

import Foundation
import ArgumentParser

struct Repeat: ParsableCommand {
    
    @Flag(help: "插入周报前")
    var insertBefor:Bool = false
    
    @Flag(help: "插入周报")
    var insert:Bool = false
    
    @Option(help: "内容")
    var input: String?
    
    @Option(help: "插入时间戳")
    var t:String?
    
    @Option(help: "插入日期")
    var d:String?
    
    @Flag(help: "查看周报")
    var check:Bool = false
    
    @Flag(help: "删除一条周报")
    var delete:Bool = false
    
    @Flag(help: "导出一周周报")
    var export:Bool = false
    
    func run() {
        guard let input = input?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        /*
         if insertBefor {
             WeeklyDataManager.insertBefor(report: input)
         } else 
         */
        if insert {
            WeeklyDataManager.insert(report: input, insertTimestamp: t, insertDate: d)
        } else if check {
            WeeklyDataManager.weeklyDataList(query: input, isDelete: delete)
        } else if export {
            WeeklyDataManager.export(input)
        } else if delete {
            WeeklyDataManager.delete(input)
        }
    }
}

Repeat.main()

