//
//  SecurityExam.swift
//  SecurityExam
//
//  Created by zhouziyuan on 2022/9/2.
//

import Foundation

class SecurityExam {
    /// 题目
    let topic: String
    /// 答案
    var answers: [String]
    
    init(topic: String, answers: [String]) {
        self.topic = topic
        self.answers = answers
    }
    
    var simple: AlfredItem {
        var item = AlfredItem()
        let subtitle: String
        var args = [String]()
        if answers.count == 1 {
            subtitle = "单选题"
            args += ["单选题：\(topic)", "", "答案："]
            args += answers
        } else {
            subtitle = "多选题，\(answers.count) 个答案"
            args += ["多选题：\(topic)", "", "答案："]
            // 多选题时，答案前面显示序号
            args += answers.enumerated().map({ "\($0.offset + 1):\($0.element)" })
        }
        item.subtitle = subtitle
        item.arg = args.joined(separator: "\n")
        item.title = topic
        return item
    }
    
    /// 当前题目的所有答案，是否在第一行显示题目
    func answerItems(isNeedTopic: Bool = true) -> [AlfredItem] {
        let args = ["题目：\(topic)"] + answers.enumerated().map({ "\($0.offset + 1):\($0.element)" })
        let arg = args.joined(separator: "\n")
        var items = answers.map({ AlfredItem.item(arg: arg, title: $0) })
        if isNeedTopic {
            let item = AlfredItem.item(arg: arg, title: "题目：\(topic)")
            items.insert(item, at: 0)
        }
        return items
    }
}

extension SecurityExam {
    #if DEBUG
        static let SecurityExamPath = Alfred.home / "Desktop/记录/信息安全&平台政策考试.json"
    #else
        static let SecurityExamPath = Alfred.localDir / "信息安全&平台政策考试.json"
    #endif
    
    /// 所有的考题
    static let allTopic: [SecurityExam] = {
        do {
            let data = try Data(contentsOf: SecurityExamPath)
            let allQuestions = try JSONSerialization.jsonObject(with: data) as? [String: [String]] ?? [:]
            return allQuestions.map({ SecurityExam(topic: $0.0, answers: $0.1) }).sorted(by: { $0.topic < $1.topic })
        } catch {
            print("考题文本读取失败：\(error.localizedDescription)")
            exit(1)
        }
    }()
    
    /// 导入新的考试题库(来源：从钉钉云课堂考试后，全部复制下来保存成文本文件)。
    class func importSecurityExam(filePath: String) -> URL? {
        guard filePath.fileExists, let importString = try? String(contentsOfFile: filePath) else {
            print("考题文本文件不存在")
            return nil
        }
        var allQuestions = allTopic
        let regex = try! Regex("\\d{1,2}\\n+[单|多]选题\\n+\\s*\\n分值:\\s*\\d\\n+得分：\\d分")
        let target = "==========="
        // 这两个值如果是一行内容，需要直接过滤掉，因为这两个值是对当前答案的判定，不是属于答案内容
        let filters = ["正确答案", "错误答案"]
        let questionLines = regex.replacingMatches(in: importString, with: target).components(separatedBy: target).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && $0.contains("正确答案：") }
        // 答案标识
        let keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]
        // 当前解析题目总数
        var count = 0
        // 相同题目数
        var same = 0
        for str in questionLines {
            // 以这个分割，前面是题目，后面是答案标识
            let array = str.components(separatedBy: "正确答案：")
            guard array.count == 2 else { continue }
            // 取出正确答案的标识
            let awswerKeys = array[1].components(separatedBy: "\n")
            // 把题目内容按行分割
            let lines = array[0].components(separatedBy: "\n")
            guard lines.count > 4 else { continue }
            // 第一行是题目
            let title = lines[0]
            var dic = [String: String]()
            var key = ""
            for line in lines {
                // 过滤掉题目和对当前答案的判定结果
                guard title != line, !filters.contains(line), !line.isEmpty else { continue }
                // 如果当前行是ABCDEF这种答案标识
                if keys.contains(line) {
                    key = line
                } else {
                    // 把答案内容放到答案标识对应的字典中
                    dic[key] = (dic[key] ?? "") + line
                }
            }
            // 只取出正确答案的内容
            let answers = dic.filter({ awswerKeys.contains($0.0) }).map({ $0.1 })
            if let item = allQuestions.filter({ $0.topic.removeSymbol == title.removeSymbol }).first { // 旧题
                same += 1
                // 把当前的答案和旧答案合并去重
                item.answers = Array(Set(answers + item.answers))
            } else { // 新题
                let item = SecurityExam(topic: title, answers: answers)
                allQuestions.append(item)
            }
            count += 1
        }
        do {
            let dic = Dictionary(uniqueKeysWithValues: allQuestions.map({ ($0.topic, $0.answers) }))
            let data = try JSONSerialization.data(withJSONObject: dic, options: [.sortedKeys, .prettyPrinted])
            try data.write(to: SecurityExamPath)
            print("解析题目数：\(count)。\n其中相同题目数：\(same)。\n生成题库数：\(allQuestions.count)\n新增：\(allQuestions.count - allTopic.count)")
            return SecurityExamPath
        } catch {
            print("保存题目失败:\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 通过题目内容查询考题，为空时，显示所有考题
    class func query(topic: String) {
        guard !topic.isEmpty else {
            var items = allTopic.map({ $0.simple })
            var item = AlfredItem()
            item.title = "总共收录 \(allTopic.count) 道考题"
            let radioCount = allTopic.filter({ $0.answers.count == 1 }).count
            item.subtitle = "单选：\(radioCount)。多选：\(allTopic.count - radioCount)"
            items.insert(item, at: 0)
            Alfred.flush(items: items)
            return
        }
        let result = allTopic.filter({ $0.topic.lowercased().contains(topic.lowercased()) })
        switch result.count {
            case 0:
                var item = AlfredItem()
                item.subtitle = topic
                item.title = "该考题还未收录"
                Alfred.flush(item: item)
            case 1:
                let item = result[0]
                let answers = item.answerItems(isNeedTopic: item.topic != topic)
                Alfred.flush(items: answers)
            default:
                let items = result.map({ $0.simple })
                Alfred.flush(items: items)
        }
    }
    
    /// 导出所有题目保存成文件
    class func export(path: String) {
        guard !path.isEmpty else {
            print("导出保存路径不能为空")
            return
        }
        do {
            let dic = Dictionary(uniqueKeysWithValues: allTopic.map { ($0.topic, $0.answers) })
            let data = try JSONSerialization.data(withJSONObject: dic, options: [.sortedKeys, .prettyPrinted])
            path.deletingLastPathComponent.createFilePath()
            path.pathRemove()
            try data.write(to: URL(fileURLWithPath: path))
            print("导出保存题目成功")
        } catch {
            print("导出保存题目失败:\(error.localizedDescription)")
        }
    }
}

extension String {
    var removeSymbol: String {
        let symbol = ["，", "？", "、", "。", ",", ".", "?"]
        var new = self
        symbol.forEach({
            new = new.replacingOccurrences(of: $0, with: "|")
        })
        return new
    }
}
