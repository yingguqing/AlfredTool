//
//  WeeklyData.swift
//  WeeklyData
//
//  Created by zhouziyuan on 2022/7/20.
//

import Cocoa

class WeeklyDataManager {
    static let thisYear = Date().format("YYYY")
    static let path = Alfred.localDir / "WeeklyData.json"

    struct WeeklyData {
        // 周报所归属的周
        let week: String
        /// 时间戳
        let timestamp: TimeInterval
        /// 周报内容
        let report: String
        /// 备注
        var remake: String
        /// 周报日期
        let date: String

        var json: [String: Any] {
            var dic: [String: Any] = ["timestamp": timestamp, "report": report]
            guard !remake.isEmpty else { return dic }
            dic.updateValue(remake, forKey: "remake")
            return dic
        }

        init?(json: [String: Any]) {
            guard let timestamp = json["timestamp"] as? TimeInterval,
                  let report = json["report"] as? String
            else {
                return nil
            }
            self.init(timestamp: timestamp, report: report)
            self.remake = json["remake"] as? String ?? ""
        }

        init(timestamp: TimeInterval = Date().timeIntervalSince1970, report: String) {
            self.timestamp = timestamp
            self.report = report
            let date = Date(timeIntervalSince1970: timestamp)
            self.date = date.format("YYYY-MM-dd")
            self.week = date.weekRange
            self.remake = ""
        }
    }

    /// 所有周报
    class func readAllWeeklyData() -> [WeeklyData] {
        do {
            let data = try Data(contentsOf: path)
            let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            return list?.compactMap { WeeklyData(json: $0) } ?? []
        } catch {
            // print("读取所有周报失败:\(error.localizedDescription)")
            return []
        }
    }

    @discardableResult
    class func save(weeklyDatas: [WeeklyData]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: weeklyDatas.map { $0.json }, options: [.sortedKeys, .prettyPrinted])
            try data.write(to: path, options: .atomic)
            return true
        } catch {
            print("保存周报失败:\(error.localizedDescription)")
            return false
        }
    }

    /// 周报列表
    class func weeklyDataList(query: String, isDelete: Bool) {
        let dateString: String
        let isList: Bool
        switch query.count {
            case 0:
                dateString = "20000101"
                isList = true
            case 1:
                dateString = thisYear + "0" + query + "01"
                isList = true
            case 2:
                dateString = thisYear + query + "01"
                isList = true
            case 4:
                dateString = thisYear + query
                isList = false
            case 6:
                dateString = query + "01"
                isList = true
            case 8:
                isList = false
                dateString = query
            case 21:
                dateString = String(query.prefix(10)).replacingOccurrences(of: "-", with: "")
                isList = false
            default:
                isList = false
                dateString = ""
        }
        guard let date = dateString.toDate()?.startOfWeek else {
            var item = AlfredItem()
            item.uid = "1"
            item.subtitle = "请检查日期是否正确"
            item.arg = ""
            item.title = "没有结果"
            Alfred.flush(item: item)
            return
        }
        if isList {
            let time = date.timeIntervalSince1970
            var dict = [String: Int]()
            readAllWeeklyData().filter { $0.timestamp >= time }.forEach {
                let count = (dict[$0.week] ?? 0) + 1
                dict.updateValue(count, forKey: $0.week)
            }
            let items = dict.keys.sorted(by: >).map { AlfredItem.item(arg: $0, title: $0, subtitle: "周报 \(dict[$0] ?? 0) 份") }
            Alfred.flush(items: items)
        } else {
            let list = readAllWeeklyData().filter { $0.week == date.weekRange }.sorted(by: { $0.timestamp < $1.timestamp })
            if list.isEmpty {
                var item = AlfredItem()
                item.uid = "1"
                item.subtitle = "该周没有周报，请检查日期是否正确"
                item.arg = ""
                item.title = "查询周报失败"
                Alfred.flush(item: item)
            } else {
                let target = isDelete ? "删除" : "导出"
                var item = AlfredItem()
                item.uid = "10"
                item.subtitle = "\(target)时期：\(date.weekRange)"
                item.arg = "~" + date.weekRange
                item.title = target + "下面所有周报"
                let items = [item] + list.enumerated().map { AlfredItem.item(arg: isDelete ? "~" + String($0.element.timestamp) : "", title: (isDelete ? "删除" : "") + $0.element.report, uid: String($0.offset + 11), subtitle: $0.element.date.dropThisYear) }
                Alfred.flush(items: items)
            }
        }
    }

    /// 导出一周的周报
    class func export(_ input: String) {
        let list = readAllWeeklyData().filter { $0.week == String(input.dropFirst()) }.sorted(by: { $0.timestamp < $1.timestamp })
        if list.isEmpty {
            print("")
        } else {
            let remakes = list.filter { !$0.remake.isEmpty }
            var array = [list.first!.week.dropThisYear.replacingOccurrences(of: "-", with: ".")]
            array += list.enumerated().map { "\($0.offset + 1).\($0.element.report)" }
            if !remakes.isEmpty {
                array.append("备注：")
                array += remakes.map { $0.remake }
            }
            print(array.joined(separator: "\n"))
        }
    }

    /// 插入周报前
    class func insertBefor(report: String) {
        let array = report.components(separatedBy: ";").filter { !$0.isEmpty }
        if array.count == 0 {
            var item = AlfredItem()
            item.uid = "1"
            item.title = "输入今天的工作任务"
            item.subtitle = "如果有备注，请在工作任务后面加上空格后再输入内容"
            item.arg = ""
            Alfred.flush(item: item)
        } else if array.count == 1 {
            let data = WeeklyData(report: report)
            var item = AlfredItem()
            item.uid = "1"
            item.subtitle = "Enter插入周报 -> " + data.week.dropThisYear
            item.arg = data.report
            item.title = data.report
            Alfred.flush(item: item)
        } else {
            let report = array.first!
            let remake = array[1]
            let data = WeeklyData(report: report)
            var item = AlfredItem()
            item.uid = "1"
            item.subtitle = "备注：" + remake + " Enter插入周报 -> " + data.week.dropThisYear
            item.arg = data.report
            item.title = data.report
            Alfred.flush(item: item)
        }
    }

    /// 插入周报
    class func insert(report: String) {
        guard !report.isEmpty else { return }
        let data = WeeklyData(report: report)
        var list = readAllWeeklyData()
        list.append(data)
        let flag = save(weeklyDatas: list) ? "成功" : "失败"
        print("插入周报" + flag)
    }

    /// 删除一条周报
    class func delete(_ input: String) {
        // 删除一周的周报
        if input.count == 22, input.contains("~") {
            var list = readAllWeeklyData()
            list.removeAll(where: { $0.week == String(input.dropFirst()) })
            let flag = save(weeklyDatas: list) ? "成功" : "失败"
            print("删除周报" + flag)
        } else if input.hasPrefix("~"), let timestamp = Int64(String(input.dropFirst())) {
            // 传入时间戳表示删除一条
            var list = readAllWeeklyData()
            list.removeAll(where: { Int64($0.timestamp) == timestamp })
            let flag = save(weeklyDatas: list) ? "成功" : "失败"
            print("删除周报" + flag)
        } else {
            print("删除周报失败，没有相应的周报")
        }
    }
}

extension String {
    var dropThisYear: String {
        return replacingOccurrences(of: Date().format("YYYY-"), with: "")
    }
}
