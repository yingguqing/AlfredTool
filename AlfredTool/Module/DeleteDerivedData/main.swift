//
//  main.swift
//  DeleteDerivedData
//
//  Created by zhouziyuan on 2022/9/28.
//

import ArgumentParser
import Foundation

/*
 OPTIONS:
   --search <search>       查询
   --delete-name <delete-name>
                           删除目录
   --delete-same-name      删除所有同名的
   -h, --help              Show help information.
 */
struct Repeat: ParsableCommand {
    @Option(help: "查询")
    var search: String?

    @Option(help: "删除目录")
    var deleteName: String?
    
    @Flag(help: "删除所有同名的")
    var deleteSameName:Bool = false

    func run() {
        if let search = search {
            DerivedData.searchList(search)
        } else if let deleteName = deleteName {
            DerivedData.delete(deleteName, isDeleteSameName: deleteSameName)
        }
    }
}

Repeat.main()

class DerivedData {
    static let DerivedDataPath = (Alfred.home / "/Library/Developer/Xcode/DerivedData").path

    /// 查询DerivedData
    class func searchList(_ input: String) {
        if DerivedDataPath.directoryExists {
            let names = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: false).filter({ $0.lastPathComponent != "ModuleCache.noindex" && !$0.lastPathComponent.hasPrefix(".") }).sorted(by: <)
            if names.isEmpty {
                var item = AlfredItem()
                item.title = "DerivedData目录没有需要删除的目录"
                Alfred.flush(item: item)
            } else if !input.isEmpty {
                let select = names.filter({ $0.lowercased().contains(input) })
                if select.isEmpty {
                    var item = AlfredItem()
                    item.title = "没有包含 \(input) 的目录"
                    Alfred.flush(item: item)
                } else {
                    let items = select.map { name in
                        var item = AlfredItem()
                        item.arg = name
                        item.subtitle = name + " · 按钮⌘可删除同名"
                        item.title =  name.lastPathComponent.components(separatedBy: "-").first!
                        return item
                    }
                    Alfred.flush(items: items)
                }
            } else {
                var items = names.map { name in
                    var item = AlfredItem()
                    item.arg = name
                    item.subtitle = name + " · 按钮⌘可删除同名"
                    item.title = name.lastPathComponent.components(separatedBy: "-").first!
                    return item
                }
                var item = AlfredItem()
                item.arg = "Delete All"
                item.subtitle = "删除DerivedData目录所有内容"
                item.title = "删除所有"
                items.insert(item, at: 0)
                Alfred.flush(items: items)
            }
        } else {
            var item = AlfredItem()
            item.subtitle = ""
            item.title = "DerivedData目录不存在"
            Alfred.flush(item: item)
        }
    }

    /// 删除相应的DerivedData
    class func delete(_ input: String, isDeleteSameName:Bool) {
        guard !input.isEmpty else { return }
        if input == "Delete All" {
            let paths = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: true)
            paths.forEach({ $0.pathRemove() })
            print("删除所有DerivedData完成")
        } else {
            var name = input
            if isDeleteSameName {
                name = input.components(separatedBy: "-").first!
            }
            let paths = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: true).filter({ $0.lastPathComponent.hasPrefix(name) })
            paths.forEach {
                $0.pathRemove()
            }
            print("删除包含 \(name) 的DerivedData完成")
        }
    }
}
