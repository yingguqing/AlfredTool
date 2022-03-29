//
//  Timestamp.swift
//  Timestamp
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

class Timestamp {
    
    static func run(_ inputStr:String) {
        let icon = AlfredUtil.itemIcon(title: "Timestamp")
        if inputStr.isEmpty || inputStr.lowercased() == "now" {
            let timestamp = Date().timeIntervalSince1970
            let item = FeedbackItem()
            item.icon = icon
            item.uid = "1"
            item.arg = String(UInt64(timestamp))
            item.title = "当前时间戳 • 秒"
            item.subtitle = item.arg
            
            let item2 = FeedbackItem()
            item2.icon = icon
            item2.uid = "2"
            item2.arg = String(UInt64(timestamp * 1000))
            item2.title = "当前时间戳 • 毫秒"
            item2.subtitle = item2.arg
            Alfred.flush(alfredItem: item, item2)
        } else if let number = TimeInterval(inputStr) {
            switch String(UInt64(number)).count {
                case 10:
                    let date = Date(timeIntervalSince1970: number)
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = date.format("YYYY-MM-dd HH:mm:ss")
                    item.title = "北京时间"
                    item.subtitle = item.arg
                    Alfred.flush(alfredItem: item)
                case 13:
                    let date = Date(timeIntervalSince1970: number/1000)
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = date.format("YYYY-MM-dd HH:mm:ss")
                    item.title = "北京时间"
                    item.subtitle = item.arg
                    Alfred.flush(alfredItem: item)
                default:
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = ""
                    item.title = "时间戳不正确定"
                    item.subtitle = "请输入正确的10位或13位的时间戳"
                    Alfred.flush(alfredItem: item)
            }
        } else  {
            let path = AlfredUtil.local(filename: "DateFormat.plist")
            if let formats = try? AlfredUtil.readPlist(path) as? [String] {
                let items = formats.map({ ($0, inputStr.toDate($0)?.timeIntervalSince1970) }).filter({ $0.1 != nil }).map { (value)->[FeedbackItem] in
                    let item = FeedbackItem()
                    item.icon = icon
                    item.uid = "1"
                    item.arg = String(UInt64(value.1!))
                    item.title = "时间戳 • 秒"
                    item.subtitle = item.arg
                    
                    let item2 = FeedbackItem()
                    item2.icon = icon
                    item2.uid = "2"
                    item2.arg = String(UInt64(value.1! * 1000))
                    item2.title = "时间戳 • 毫秒"
                    item2.subtitle = item2.arg
                    
                    
                    return [item, item2]
                }
                let result = items.flatMap({ $0 })
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
}
