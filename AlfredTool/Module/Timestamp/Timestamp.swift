//
//  Timestamp.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

class Timestamp {
    
    static func run(_ inputStr: String, formats:[String]) {
        if formats.isEmpty {
            let item = AlfredItem.item(arg: "没有日期格式化", title: "没有日期格式化", subtitle: "请先在Alfred参数里配置日志格式化")
            Alfred.flush(item: item)
            return
        }
        
        if inputStr.isEmpty || inputStr.lowercased() == "now" {
            let date = Date()
            let timestamp = date.timeIntervalSince1970
            
            var arg = String(UInt64(timestamp))
            let item1 = AlfredItem.item(arg: arg, title: arg, subtitle: "当前时间戳 • 秒")
            
            arg = String(UInt64(timestamp * 1000))
            let item2 = AlfredItem.item(arg: arg, title: arg, subtitle: "当前时间戳 • 毫秒")
            
            // 格式化当前时间，显示所有格式化样式
            let flushItems = [item1, item2] + format(date: date, formats: formats)
            
            Alfred.flush(items: flushItems)
        } else if let number = TimeInterval(inputStr) {
            let count = String(UInt64(number)).count
            let date: Date
            if count >= 10, count <= 13 {
                date = Date(timeIntervalSince1970: number / pow(10, Double(count - 10)))
            } else {
                let item = AlfredItem.item(title: "时间戳不正确定", subtitle: "请输入正确的10位或13位的时间戳")
                Alfred.flush(item: item)
                return
            }
            let flushItems = format(date: date, formats: formats)
            Alfred.flush(items: flushItems)
        } else {
            let items = formats.map { ($0, inputStr.toDate($0)?.timeIntervalSince1970) }.filter { $0.1 != nil }.map { value -> [AlfredItem] in
                var arg = String(UInt64(value.1!))
                let item = AlfredItem.item(arg: arg, title: arg, subtitle: "时间戳 • 秒")
                
                // 末尾拼接个随机毫秒
                arg = String(UInt64(value.1! * 1000) + UInt64(arc4random_uniform(1000)))
                let item2 = AlfredItem.item(arg: arg, title: arg, subtitle: "时间戳 • 毫秒")
                
                return [item, item2]
            }
            let result = items.flatMap { $0 }
            if !result.isEmpty {
                Alfred.flush(items: result)
            }
        }

        let item = AlfredItem.item(title: "转换失败", subtitle: "日期格式不存在或输入错误")
        Alfred.flush(item: item)
    }
    
    /// 输出日期的所有格式化样式结果
    /// - Parameter date: 日期
    /// - Returns: 结果
    static func format(date: Date, formats:[String]) -> [AlfredItem] {
        let flushItems = formats.map({
            // 格式化当前时间，显示所有格式化样式
            AlfredItem.item(arg: date.format($0), title: date.format($0), subtitle: "北京时间 • \($0)")
        })
        return flushItems
    }
}

