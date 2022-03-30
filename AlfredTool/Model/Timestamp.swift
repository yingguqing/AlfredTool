//
//  Timestamp.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

class Timestamp {
    static let icon = AlfredUtil.itemIcon(title: "Timestamp")
    static let UserDateFormats = AlfredUtil.userConfig("DateFormat") as? [String] ?? []
    
    static func run(_ inputStr: String) {
        if inputStr.isEmpty || inputStr.lowercased() == "now" {
            let date = Date()
            let timestamp = date.timeIntervalSince1970
            var flushItems = [AlfredItem]()
            let item = AlfredItem()
            item.icon = icon
            item.uid = "1"
            item.arg = String(UInt64(timestamp))
            item.title = item.arg
            item.subtitle = "当前时间戳 • 秒"
            flushItems.append(item)
            
            let item2 = AlfredItem()
            item2.icon = icon
            item2.uid = "2"
            item2.arg = String(UInt64(timestamp * 1000))
            item2.title = item2.arg
            item2.subtitle = "当前时间戳 • 毫秒"
            flushItems.append(item2)
            
            // 格式化当前时间，显示所有格式化样式
            flushItems += format(date: date)
            
            Alfred.flush(alfredItems: flushItems)
        } else if let number = TimeInterval(inputStr) {
            let count = String(UInt64(number)).count
            let date: Date
            if count >= 10, count <= 13 {
                date = Date(timeIntervalSince1970: number / pow(10, Double(count - 10)))
            } else {
                let item = AlfredItem()
                item.icon = icon
                item.uid = "1"
                item.arg = ""
                item.title = "时间戳不正确定"
                item.subtitle = "请输入正确的10位或13位的时间戳"
                Alfred.flush(alfredItem: item)
                return
            }
            let flushItems = format(date: date)
            Alfred.flush(alfredItems: flushItems)
        } else {
            let items = UserDateFormats.map { ($0, inputStr.toDate($0)?.timeIntervalSince1970) }.filter { $0.1 != nil }.map { value -> [AlfredItem] in
                let item = AlfredItem()
                item.icon = icon
                item.uid = "1"
                item.arg = String(UInt64(value.1!))
                item.title = item.arg
                item.subtitle = "时间戳 • 秒"
                
                let item2 = AlfredItem()
                item2.icon = icon
                item2.uid = "2"
                item2.arg = String(UInt64(value.1! * 1000))
                item2.title = item2.arg
                item2.subtitle = "时间戳 • 毫秒"
                
                return [item, item2]
            }
            let result = items.flatMap { $0 }
            if !result.isEmpty {
                Alfred.flush(alfredItems: result)
            }
        }

        let item = AlfredItem()
        item.icon = icon
        item.uid = "1"
        item.arg = ""
        item.title = "转换失败"
        item.subtitle = "日期格式不存在或输入错误"
        Alfred.flush(alfredItem: item)
    }
    
    /// 输出日期的所有格式化样式结果
    /// - Parameter date: 日期
    /// - Returns: 结果
    static func format(date: Date) -> [AlfredItem] {
        var flushItems = [AlfredItem]()
        // 格式化当前时间，显示所有格式化样式
        for (index, value) in UserDateFormats.enumerated() {
            let item = AlfredItem()
            item.icon = icon
            item.uid = String(index + 3)
            item.arg = date.format(value)
            item.title = item.arg
            item.subtitle = "北京时间 • \(value)"
            flushItems.append(item)
        }
        return flushItems
    }
    
    /// 新增一条日期格式化样式
    static func add(dateFormat: String) {
        if dateFormat.isEmpty {
            let item = AlfredItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "新增日期格式化样式"
            item.subtitle = "请输入新的样式，如：YYYY-MM-dd HH:mm:ss"
            Alfred.flush(alfredItem: item)
        } else if UserDateFormats.contains(dateFormat) {
            let item = AlfredItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "新增日期格式化样式"
            item.subtitle = "\(dateFormat) 已存在"
            Alfred.flush(alfredItem: item)
        } else {
            let item = AlfredItem()
            item.icon = icon
            item.uid = "1"
            item.arg = "save add \(dateFormat)"
            item.title = "新增日期格式化样式"
            item.subtitle = "新增 \(dateFormat)"
            Alfred.flush(alfredItem: item)
        }
    }
    
    /// 删除一条日期格式化样式
    static func remove(dateFormat: String) {
        if dateFormat.isEmpty {
            let item = AlfredItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "删除日期格式化样式"
            item.subtitle = "请输入删除样式，如：YYYY-MM-dd HH:mm:ss"
            Alfred.flush(alfredItem: item)
        } else {
            let items = UserDateFormats.filter { $0.hasPrefix(dateFormat) }.map { value -> AlfredItem in
                let item = AlfredItem()
                item.icon = icon
                item.uid = "1"
                item.arg = "save del \(value)"
                item.title = "删除日期格式化样式"
                item.subtitle = "删除 \(value)"
                return item
            }
            if !items.isEmpty {
                Alfred.flush(alfredItems: items)
            } else {
                let item = AlfredItem()
                item.icon = icon
                item.uid = "1"
                item.arg = ""
                item.title = "删除日期格式化样式"
                item.subtitle = "\(dateFormat) 不存在"
                Alfred.flush(alfredItem: item)
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
        AlfredUtil.saveUserConfig(key: "DateFormat", value: formats)
        print(isAdd ? "添加格式样式成功" : "删除格式样式成功")
    }
}
