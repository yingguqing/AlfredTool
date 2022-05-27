//
//  Timestamp.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

class Timestamp {
    static let icon = AlfredItem.Icon.forTitle("Timestamp")
    static let UserDateFormats = userConfig("DateFormat") as? [String] ?? []
    
    static func run(_ inputStr: String) {
        if inputStr.isEmpty || inputStr.lowercased() == "now" {
            let date = Date()
            let timestamp = date.timeIntervalSince1970
            
            var arg = String(UInt64(timestamp))
            let item1 = AlfredItem.item(arg: arg, title: arg, subtitle: "当前时间戳 • 秒", icon: icon)
            
            arg = String(UInt64(timestamp * 1000))
            let item2 = AlfredItem.item(arg: arg, title: arg, subtitle: "当前时间戳 • 毫秒", icon: icon)
            
            // 格式化当前时间，显示所有格式化样式
            let flushItems = [item1, item2] + format(date: date)
            
            Alfred.flush(items: flushItems)
        } else if let number = TimeInterval(inputStr) {
            let count = String(UInt64(number)).count
            let date: Date
            if count >= 10, count <= 13 {
                date = Date(timeIntervalSince1970: number / pow(10, Double(count - 10)))
            } else {
                let item = AlfredItem.item(title: "时间戳不正确定", subtitle: "请输入正确的10位或13位的时间戳", icon: icon)
                Alfred.flush(item: item)
                return
            }
            let flushItems = format(date: date)
            Alfred.flush(items: flushItems)
        } else {
            let items = UserDateFormats.map { ($0, inputStr.toDate($0)?.timeIntervalSince1970) }.filter { $0.1 != nil }.map { value -> [AlfredItem] in
                var arg = String(UInt64(value.1!))
                let item = AlfredItem.item(arg: arg, title: arg, subtitle: "时间戳 • 秒", icon: icon)
                
                // 末尾拼接个随机毫秒
                arg = String(UInt64(value.1! * 1000) + UInt64(arc4random_uniform(1000)))
                let item2 = AlfredItem.item(arg: arg, title: arg, subtitle: "时间戳 • 毫秒", icon: icon)
                
                return [item, item2]
            }
            let result = items.flatMap { $0 }
            if !result.isEmpty {
                Alfred.flush(items: result)
            }
        }

        let item = AlfredItem.item(title: "转换失败", subtitle: "日期格式不存在或输入错误", icon: icon)
        Alfred.flush(item: item)
    }
    
    /// 输出日期的所有格式化样式结果
    /// - Parameter date: 日期
    /// - Returns: 结果
    static func format(date: Date) -> [AlfredItem] {
        let flushItems = UserDateFormats.map({
            // 格式化当前时间，显示所有格式化样式
            AlfredItem.item(arg: date.format($0), title: date.format($0), subtitle: "北京时间 • \($0)", icon: icon)
        })
        return flushItems
    }
    
    /// 新增一条日期格式化样式
    static func add(dateFormat: String) {
        var item = AlfredItem.item(title: "新增日期格式化样式", icon: icon)
        if dateFormat.isEmpty {
            item.subtitle = "请输入新的样式，如：YYYY-MM-dd HH:mm:ss"
        } else if UserDateFormats.contains(dateFormat) {
            item.subtitle = "\(dateFormat) 已存在"
        } else {
            item.arg = "save add \(dateFormat)"
            item.subtitle = "新增 \(dateFormat)"
        }
        Alfred.flush(item: item)
    }
    
    /// 删除一条日期格式化样式
    static func remove(dateFormat: String) {
        var item = AlfredItem.item(title: "删除日期格式化样式", icon: icon)
        if dateFormat.isEmpty {
            item.subtitle = "请输入删除样式，如：YYYY-MM-dd HH:mm:ss"
            Alfred.flush(item: item)
        } else {
            let items = UserDateFormats.filter { $0.hasPrefix(dateFormat) }.map {
                AlfredItem.item(arg: "save del \($0)", title: "删除日期格式化样式", subtitle: "删除 \($0)", icon: icon)
            }
            if !items.isEmpty {
                Alfred.flush(items: items)
            } else {
                item.subtitle = "\(dateFormat) 不存在"
                Alfred.flush(item: item)
            }
        }
    }
    
    /// 保存日期格式化样式
    /// - Parameter dateFormats: json格式
    static func save(dateFormats: String) {
        let isAdd = dateFormats.hasPrefix("add ")
        let formats:[String]
        let value = String(dateFormats.dropFirst(4))
        if isAdd {
            formats = UserDateFormats + [value]
        } else {
            formats = UserDateFormats.filter({ $0 != value })
        }
        saveUserConfig(key: "DateFormat", value: formats)
        print(isAdd ? "添加格式样式成功" : "删除格式样式成功")
    }
}
