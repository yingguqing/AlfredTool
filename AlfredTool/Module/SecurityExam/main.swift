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
 --export-path <export-path> 导出所有考试题目路径
 --topic <topic>         考试题目内容
 --import-path <import-path> 收录考试题目答案
 --access-key-id <access-key-id> OSS的上传文件参数Key Id
 --access-key-secret <access-key-secret> OSS的上传文件参数accessKeySecret
 --security-token <security-token> OSS的上传文件参数securityToken
 */
struct Repeat: ParsableCommand {
    
    @Option(help: "导出所有考试题目路径")
    var exportPath:String?
    
    @Option(help: "考试题目内容")
    var topic: String?
    
    @Option(help: "收录考试题目答案")
    var importPath: String?
    
    
    @Option(help: "OSS的上传文件参数Key Id")
    var accessKeyId: String?
    @Option(help: "OSS的上传文件参数accessKeySecret")
    var accessKeySecret: String?
    @Option(help: "OSS的上传文件参数securityToken")
    var securityToken: String?
    
    func run() {
        if let topic = topic {
            SecurityExam.query(topic: topic)
        } else if let importPath = importPath {
            let url = SecurityExam.importSecurityExam(filePath: importPath)
            guard let url = url else { return }
            let upload = UploadFileToOss(accessKeyId: accessKeyId, accessKeySecret: accessKeySecret, securityToken: securityToken)
            Task {
                await upload?.upload(url: url, toPath: "文档/\(url.lastPathComponent)")
            }
            while upload?.isFinish == false {
                sleep(1)
            }
        } else if let exportPath = exportPath {
            SecurityExam.export(path: exportPath)
        }
    }
}

Repeat.main()

