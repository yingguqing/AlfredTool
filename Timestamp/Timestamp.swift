//
//  Timestamp.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

class Timestamp {
    static let icon = AlfredUtil.itemIcon(title: "Timestamp")
    static let path = AlfredUtil.local(filename: "DateFormat.json")
    
    static func run(_ inputStr: String) {
        if inputStr.isEmpty || inputStr.lowercased() == "now" {
            let date = Date()
            let timestamp = date.timeIntervalSince1970
            var flushItems = [FeedbackItem]()
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = String(UInt64(timestamp))
            item.title = item.arg
            item.subtitle = "当前时间戳 • 秒"
            flushItems.append(item)
            
            let item2 = FeedbackItem()
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
            let date:Date
            if count >= 10, count <= 13 {
                date = Date(timeIntervalSince1970: number / pow(10, Double(count - 10)))
            } else {
                let item = FeedbackItem()
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
            if let str = try? String(contentsOfFile: path), let formats = try? JSONSerialization.jsonObject(with: Data(str.utf8)) as? [String] {
                let items = formats.map { ($0, inputStr.toDate($0)?.timeIntervalSince1970) }.filter { $0.1 != nil }.map { value -> [FeedbackItem] in
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = String(UInt64(value.1!))
                    item.title = item.arg
                    item.subtitle = "时间戳 • 秒"
                    
                    let item2 = FeedbackItem()
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
        }

        let item = FeedbackItem()
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
    static func format(date:Date) -> [FeedbackItem] {
        var flushItems = [FeedbackItem]()
        // 格式化当前时间，显示所有格式化样式
        if let str = try? String(contentsOfFile: path), let formats = try? JSONSerialization.jsonObject(with: Data(str.utf8)) as? [String] {
            for (index, value) in formats.enumerated() {
                let item = FeedbackItem()
                item.icon = icon
                item.uid = String(index + 3)
                item.arg = date.format(value)
                item.title = item.arg
                item.subtitle = "北京时间 • \(value)"
                flushItems.append(item)
            }
        }
        return flushItems
    }
    
    /// 新增一条日期格式化样式
    static func add(dateFormat: String) {
        if dateFormat.isEmpty {
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "新增日期格式化样式"
            item.subtitle = "请输入新的样式，如：YYYY-MM-dd HH:mm:ss"
            Alfred.flush(alfredItem: item)
        } else {
            var newFormats = [String]()
            if let str = try? String(contentsOfFile: path), let formats = try? JSONSerialization.jsonObject(with: Data(str.utf8)) as? [String] {
                if formats.contains(dateFormat) {
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = ""
                    item.title = "新增日期格式化样式"
                    item.subtitle = "\(dateFormat) 已存在"
                    Alfred.flush(alfredItem: item)
                } else {
                    newFormats = formats
                }
            }
            newFormats.append(dateFormat)
            let data = try? JSONSerialization.data(withJSONObject: newFormats, options: .prettyPrinted)
            let arg:String
            if let data = data, let argStr = String(data: data, encoding: .utf8), !argStr.isEmpty {
                arg = "save add \(argStr)"
            } else {
                arg = ""
            }
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = arg
            item.title = "新增日期格式化样式"
            item.subtitle = dateFormat
            Alfred.flush(alfredItem: item)
        }
    }
    
    /// 删除一条日期格式化样式
    static func remove(dateFormat: String) {
        if dateFormat.isEmpty {
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "删除日期格式化样式"
            item.subtitle = "请输入删除样式，如：YYYY-MM-dd HH:mm:ss"
            Alfred.flush(alfredItem: item)
        } else {
            if let str = try? String(contentsOfFile: path), let formats = try? JSONSerialization.jsonObject(with: Data(str.utf8)) as? [String] {
                let items = formats.filter({ $0.hasPrefix(dateFormat) }).map { (value) -> FeedbackItem in
                    let newFormats = formats.filter { $0 != value }
                    let data = try? JSONSerialization.data(withJSONObject: newFormats, options: .prettyPrinted)
                    let arg:String
                    if let data = data, let argStr = String(data: data, encoding: .utf8), !argStr.isEmpty {
                        arg = "save del \(argStr)"
                    } else {
                        arg = ""
                    }
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = arg
                    item.title = "删除日期格式化样式"
                    item.subtitle = "删除 \(value)"
                    return item
                }
                Alfred.flush(alfredItems: items)
            }
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = ""
            item.title = "删除日期格式化样式"
            item.subtitle = "\(dateFormat) 不存在"
            Alfred.flush(alfredItem: item)
        }
    }
    
    /// 保存日期格式化样式
    /// - Parameter dateFormats: json格式
    static func save(dateFormats: String) {
        let isAdd = dateFormats.hasPrefix("add ")
        let data = String(dateFormats.dropFirst(4)).data(using: .utf8)
        let path = AlfredUtil.local(filename: "DateFormat.json")
        try? data?.write(to: URL(fileURLWithPath: path), options: .atomic)
        print(isAdd ? "添加格式样式成功" : "删除格式样式成功")
    }
}
