//
//  Parser.swift
//  AlfredTool
//
//  Created by 影孤清 on 2025/6/23.
//

import Foundation

struct QAInfo: Decodable {
    let `as`: [String]
    let qs: [Question]
    let correct_info: [Bool]

    static func parser(with url: URL) throws -> [SecurityExam] {
        let data = try Data(contentsOf: url)
        let qaInfo = try QAInfo.decode(from: data)
        var all: [SecurityExam] = []
        for (index, value) in qaInfo.qs.enumerated() {
            let answers = qaInfo.as[index].components(separatedBy: "##``##").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            let items = value.items.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            guard !answers.isEmpty, Set(answers).subtracting(items).isEmpty else { continue }
            let item = SecurityExam(topic: value.question, answers: answers)
            all.append(item)
        }
        guard qaInfo.qs.count == all.count else {
            throw "解析题库失败"
        }
        return all
    }
}

struct Question: Decodable {
    let question: String
    let items: [String]
}

private struct ResponseWrapper: Decodable {
    let status: StatusWrapper

    struct StatusWrapper: Decodable {
        let qa_info: QAInfo
    }
}

extension QAInfo {
    static func decode(from data: Data) throws -> QAInfo {
        // 先解析到中间结构体
        let wrapper = try JSONDecoder().decode(ResponseWrapper.self, from: data)
        // 直接返回内层需要的数据
        return wrapper.status.qa_info
    }
}
