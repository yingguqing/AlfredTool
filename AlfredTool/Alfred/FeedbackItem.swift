//
//  FeedbackItem.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation

public class FeedbackItem: AlfredItem {
    public var uid: String = "" // 结果以uid排序
    public var arg: String = ""
    public var autocomplete: String = ""
    public var title: String = ""
    public var icon: String = ""
    public var subtitle: String = ""
    
    public init() {
        
    }
}
