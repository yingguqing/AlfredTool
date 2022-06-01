//
//  Date.swift
//  AlfredTool
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

extension DateFormatter {
    convenience init(_ format:String) {
        self.init()
        self.dateFormat = format
        // 转成中国时区，上海时间
        self.timeZone = TimeZone(identifier: "Asia/Shanghai")
    }
}

extension Date {
    
    static func today(_ format:String="YYYY/MM/dd") -> String {
        return Date().format(format)
    }
    
    static func now(_ format:String="YYYY-MM-dd HH:mm:ss") -> String {
        return Date().format(format)
    }
    
    func format(_ format:String="YYYY-MM-dd HH:mm:ss") -> String {
        let dformatter = DateFormatter(format)
        return dformatter.string(from: self)
    }
}
