//
//  SearchOpen.swift
//  SearchOpen
//
//  Created by zhouziyuan on 2022/7/27.
//

import Cocoa

class SearchOpen {
    static let configPath = Alfred.localDir / "UserFileInfo.json"

    struct File {
        /// 文件显示别名，如果没有设置，就显示文件名
        let name: String
        /// 文件路径
        let path: String
        /// 除了名字和文件名以外的查询内容
        let search: String
        /// 使用app打开
        let app: String
        
        var arg:String {
            let out = "'" + path + "'"
            guard app.fileExists else { return out }
            return "-a '\(app)' " + out
        }
        
        init?(json: [String: String], defaultApp:String?) {
            guard let path = json["path"], path.fileExists || path.directoryExists else { return nil }
            self.path = path
            let name = json["name"] ?? ""
            if name.isEmpty {
                self.name = path.fileNameWithoutExtension
            } else {
                self.name = name
            }
            self.search = json["search"] ?? ""
            self.app = json["app"] ?? defaultApp ?? ""
        }
        
        /// 有查询内容时，判断当前文件是否符合
        func isValid(_ input: String) -> Bool {
            guard !input.isEmpty else { return true }
            return ![name, search, path.fileNameWithoutExtension].filter { $0.lowercased().contains(input.lowercased()) }.isEmpty
        }
        
        /// alfred的item项
        func item() -> AlfredItem {
            var item = AlfredItem()
            // 设置uid，用于alfred记忆，最近选择的排在前面
            item.uid = path
            item.subtitle = path
            item.arg = arg
            item.quicklookurl = URL(fileURLWithPath: path)
            item.title = name
            item.icon = .ofFile(at: URL(fileURLWithPath: path))
            return item
        }
        
        static var empty:AlfredItem = {
            var item = AlfredItem()
            item.uid = "0"
            item.subtitle = "没有查询到包含关键词的文件，可以在配置文件中新增。"
            item.arg = " '" + SearchOpen.configPath.path + "'"
            item.title = "没有结果"
            return item
        }()
    }
    
    /// 检查文件
    /// - Parameters:
    ///   - group: 组
    ///   - input: 关键词
    ///   - isOpen: 是否打开文件
    class func searchFile(group: String, input: String) {
        do {
            let data = try Data(contentsOf: configPath)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            let allApp = json["App"] as? [String: String]
            guard let list = json[group] as? [[String: String]] else {
                Alfred.flush(item: File.empty)
                return
            }
            let defaultApp = allApp?[group]
            let items = list.compactMap { File(json: $0, defaultApp: defaultApp) }.filter { $0.isValid(input) }.map { $0.item() }
            guard !items.isEmpty else {
                Alfred.flush(item: File.empty)
                return
            }
            Alfred.flush(items: items)
        } catch {
            print("解析记录失败")
        }
    }
}
