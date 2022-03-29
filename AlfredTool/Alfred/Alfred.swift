//
//  Alfred.swift
//  AlfredWorkflow
//
//  Created by zhouziyuan on 2022/3/26.
//
import Foundation

public class Alfred {
    /// 回调内容给Alfred
    /// - Parameters:
    ///   - alfredItems: 显示item项
    ///   - isExit: 是否结束命令
    public static func flush(alfredItems:[AlfredItem], isExit:Bool=true) {
        print(alfredItems.xml.xmlString)
        guard isExit else { return }
        print("\n")
        exit(EX_USAGE)
    }
    
    /// 回调内容给Alfred
    /// - Parameters:
    ///   - alfredItem: 显示item项
    ///   - isExit: 是否结束命令
    public static func flush(alfredItem: AlfredItem..., isExit:Bool=true) {
        flush(alfredItems: alfredItem, isExit: isExit)
    }
    
    /// 通过bundle id把内容发送到Alfred里
    /// - Parameters:
    ///   - content: 内容
    public static func sendToAlfred(_ content:String, bundleId:String?=nil) {
        let source = """
        tell application id "com.runningwithcrayons.Alfred" to run trigger "feedback" in workflow "\(bundleId ?? AlfredUtil.bundleID)" with argument "\(content)"
        """
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(nil)
    }
}
