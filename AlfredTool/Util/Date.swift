//
//  Date.swift
//  AlfredTool
//
//  Created by zhouziyuan on 2022/3/30.
//

import Foundation

extension String {
    func toDate(_ format:String="YYYYMMdd") -> Date? {
        let mat = DateFormatter(format)
        return mat.date(from: self)
    }
}

extension DateFormatter {
    convenience init(_ format: String) {
        self.init()
        self.dateFormat = format
        // 转成中国时区，上海时间
        self.timeZone = TimeZone(identifier: "Asia/Shanghai")
    }
}

extension Date {
    static func today(_ format: String = "YYYY/MM/dd") -> String {
        return Date().format(format)
    }

    static func now(_ format: String = "YYYY-MM-dd HH:mm:ss") -> String {
        return Date().format(format)
    }

    func format(_ format: String = "YYYY-MM-dd HH:mm:ss") -> String {
        let dformatter = DateFormatter(format)
        return dformatter.string(from: self)
    }
}

extension Date {

    // 该时间所在周的第一天日期(2017年12月17日 00:00:00)
    var startOfWeek: Date {
        let calendar = NSCalendar.current

        let components = calendar.dateComponents(
            Set([.yearForWeekOfYear, .weekOfYear]), from: self)

        return calendar.date(from: components)!
    }

    // 该时间所在周的最后一天日期(2017年12月23日 00:00:00)
    var endOfWeek: Date {
        let calendar = NSCalendar.current

        var components = DateComponents()

        components.day = 6

        return calendar.date(byAdding: components, to: self.startOfWeek)!
    }
    
    // 一周范围时期
    var weekRange:String {
        let start = self.startOfWeek.format("YYYY-MM-dd")
        let end = self.endOfWeek.format("YYYY-MM-dd")
        return start + "~" + end
    }
}
