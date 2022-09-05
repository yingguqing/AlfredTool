//
//  main.swift
//  SecurityExam
//
//  Created by zhouziyuan on 2022/9/2.
//

/// 安全考试
import Foundation
import ArgumentParser

/*
 --export-path  导出所有考试题目路径
 --topic        考试题目内容
 --import-path  收录考试题目答案
 */
struct Repeat: ParsableCommand {
    
    @Option(help: "导出所有考试题目路径")
    var exportPath:String?
    
    @Option(help: "考试题目内容")
    var topic: String?
    
    @Option(help: "收录考试题目答案")
    var importPath: String?
    
    func run() {
        if let topic = topic {
            SecurityExam.query(topic: topic)
        } else if let importPath = importPath {
            SecurityExam.importSecurityExam(filePath: importPath)
        } else if let exportPath = exportPath {
            SecurityExam.export(path: exportPath)
        }
    }
}

Repeat.main()

