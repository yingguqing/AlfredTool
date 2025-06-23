//
//  SecurityExam.swift
//  SecurityExam
//
//  Created by zhouziyuan on 2022/9/2.
//

import ArgumentParser
import Foundation

/**
 --topic <topic>         考试题目内容
 --is-update    更新本地题库
 --import-path <import-path> 收录考试题目答案
 */
/// 安全考试
@main
struct Repeat: AsyncParsableCommand {
    @Option(help: "考试题目内容")
    var topic: String?

    @Option(help: "收录考试题目答案")
    var importPath: String?

    @Flag(help: "更新题库")
    var isUpdate:Bool = false
    
    mutating func run() async throws {
        if isUpdate {
            let crc64 = SecurityExam.SecurityExamPath.crc64()
            let result:[String:String] = try await VaporData(api: "download", params: [SecurityExam.FileName: crc64]).send()
            guard let value = result[SecurityExam.FileName] else {
                throw "获取题库更新链接失败。"
            }
            guard !value.isEmpty else {
                print("不需要更新。")
                return
            }
            guard value.hasPrefix("http"), let url = URL(string: value) else {
                throw value
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: SecurityExam.SecurityExamPath)
            print("更新题库成功。")
        } else if let topic = topic {
            SecurityExam.query(topic: topic)
        } else if let importPath = importPath {
            let url = try SecurityExam.importSecurityExam(filePath: importPath)
            let uploadURL:String = try await VaporData(api: "upload", params: SecurityExam.FileName).send()
            let data = try Data(contentsOf: url)
            let result = try await Upload(url: uploadURL, data: data).send()
            let crc64 = SecurityExam.SecurityExamPath.crc64()
            guard crc64 == result else { throw "上传题库失败" }
            print("上传题库成功。")
        }
    }
}

struct SecurityExam {
    /// 题目
    let topic: String
    /// 答案
    let answers: [String]

    var simple: AlfredItem {
        var item = AlfredItem()
        let subtitle: String
        var args = [String]()
        if answers.count == 1 {
            subtitle = "答案：\(answers.joined())"
            args += ["单选题：\(topic)", "", "答案："]
            args += answers
        } else {
            let maxLength = 10
            let subAnswers = answers.enumerated().map({ "\($0.offset + 1).\(String($0.element.prefix(min(maxLength, $0.element.count))))" }).joined(separator: " ")
            subtitle = "答案：\(subAnswers)"
            args += ["多选题：\(topic)", "", "答案："]
            // 多选题时，答案前面显示序号
            args += answers.enumerated().map({ "答案\($0.offset + 1):\($0.element)" })
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
        var items = answers.enumerated().map({ AlfredItem.item(arg: arg, title: "答案\($0.offset + 1):\($0.element)") })
        if isNeedTopic {
            let item = AlfredItem.item(arg: arg, title: "题目：\(topic)")
            items.insert(item, at: 0)
        }
        return items
    }
}

extension SecurityExam {
    static let FileName = "文档/信息安全&平台政策考试.json"
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
    static func importSecurityExam(filePath: String) throws -> URL {
        guard filePath.fileExists else { throw "考题文本文件不存在" }
        var allQuestions = allTopic
        let newQuestions = try QAInfo.parser(with: filePath.fileURL)
        // 相同题目数
        var same = 0
        newQuestions.forEach({ item in
            if let index = allQuestions.firstIndex(where: { $0.topic.removeSymbol == item.topic.removeSymbol }) {
                same += 1
                let answers = Set(allQuestions[index].answers).union(item.answers)
                guard answers.count != item.answers.count else { return }
                let new = SecurityExam(topic: item.topic, answers: Array(answers))
                allQuestions.remove(at: index)
                allQuestions.append(new)
            } else { // 新题
                allQuestions.append(item)
            }
        })
        let dic = Dictionary(uniqueKeysWithValues: allQuestions.map({ ($0.topic, $0.answers.sorted(by: <)) }))
        let data = try JSONSerialization.data(withJSONObject: dic, options: [.sortedKeys, .prettyPrinted])
        try data.write(to: SecurityExamPath)
        print("解析题目数：\(newQuestions.count)。\n其中相同题目数：\(same)。\n新增：\(allQuestions.count - allTopic.count)。\n生成题库数：\(allQuestions.count)。")
        return SecurityExamPath
    }

    /// 通过题目内容查询考题，为空时，显示所有考题
    static func query(topic: String) {
        guard !topic.isEmpty else {
            var items = allTopic.map({ $0.simple })
            var item = AlfredItem()
            item.title = "总共收录 \(allTopic.count) 道考题"
            let radioCount = allTopic.filter({ $0.answers.count == 1 }).count
            item.subtitle = "单选：\(radioCount)，多选：\(allTopic.count - radioCount)。"
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
}

extension String {
    var removeSymbol: String {
        let symbol = ["，", "？", "、", "。", ",", ".", "?", "/"]
        var new = self
        symbol.forEach({
            new = new.replacingOccurrences(of: $0, with: "|")
        })
        return new
    }
}
