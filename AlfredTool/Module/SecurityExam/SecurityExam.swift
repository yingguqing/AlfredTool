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
        static let SecurityExamPath = Alfred.home / "Desktop/记录/考题记录/信息安全&平台政策考试.json"
    #else
        static let SecurityExamPath = Alfred.localDir / "信息安全&平台政策考试.json"
    #endif
    
    /// 所有的考题
    static let allTopic: [SecurityExam] = {
        do {
            let data = try Data(contentsOf: SecurityExamPath)
            let allQuestions = try JSONSerialization.jsonObject(with: data) as? [String: [String]] ?? [:]
            return allQuestions.map { SecurityExam(topic: $0.0, answers: $0.1) }
        } catch {
            print("考题文本读取失败：\(error.localizedDescription)")
            exit(1)
        }
    }()
    
    /// 导入新的考试题库(来源：从钉钉云课堂考试后，全部复制下来保存成文本文件)
    class func importSecurityExam(filePath: String) {
        guard filePath.fileExists, let importString = try? String(contentsOfFile: filePath) else {
            print("考题文本文件不存在")
            return
        }
        var allQuestions = allTopic
        let regex = try! Regex("\\d{1,2}\\n+[单|多]选题\\n+\\s*\\n分值:\\s*\\d\\n+得分：\\d分")
        let target = "==========="
        let filters = ["正确答案", "错误答案"]
        let questionLines = regex.replacingMatches(in: importString, with: target).components(separatedBy: target).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && $0.contains("正确答案：") }
        let keys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]
        var count = 0
        var same = 0
        for str in questionLines {
            let array = str.components(separatedBy: "正确答案：")
            guard array.count == 2 else { continue }
            let awswerKeys = array[1].components(separatedBy: "\n")
            let lines = array[0].components(separatedBy: "\n")
            guard lines.count > 4 else { continue }
            let title = lines[0]
            var dic = [String: String]()
            var key = ""
            for line in lines {
                guard title != line, !filters.contains(line), !line.isEmpty else { continue }
                if keys.contains(line) {
                    key = line
                } else {
                    dic[key] = (dic[key] ?? "") + line
                }
            }
            let answers = dic.filter { awswerKeys.contains($0.0) }.map { $0.1 }
            if let item = allQuestions.filter({ $0.topic == title }).first { // 旧题
                same += 1
                // 把当前的答案和旧答案合并去重
                item.answers = Array(Set(answers + item.answers))
            } else { // 新题
                let item = SecurityExam(topic: title, answers: answers)
                print(title)
                allQuestions.append(item)
            }
            count += 1
        }
        do {
            let dic = Dictionary(uniqueKeysWithValues: allQuestions.map { ($0.topic, $0.answers) })
            let data = try JSONSerialization.data(withJSONObject: dic, options: [.sortedKeys, .prettyPrinted])
            try data.write(to: SecurityExamPath)
            print("解析题目数：\(count)。\n其中相同题目数：\(same)。\n生成题库数：\(allQuestions.count)\n新增：\(allQuestions.count - allTopic.count)")
        } catch {
            print("保存题目失败:\(error.localizedDescription)")
        }
    }
    
    /// 通过题目内容查询考题，为空时，显示所有考题
    class func query(topic: String) {
        guard !topic.isEmpty else {
            let items = allTopic.map({ $0.simple })
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
