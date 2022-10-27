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
/// 删除xcode项目DerivedData
struct Repeat: ParsableCommand {
    @Option(help: "查询")
    var search: String?

    @Option(help: "删除目录")
    var deleteName: String?
    

    func run() {
        if let search = search {
            DerivedData.searchList(search)
        } else if let deleteName = deleteName {
            DerivedData.delete(deleteName)
        }
    }
}

Repeat.main()

class DerivedData {
    static let DerivedDataPath = (Alfred.home / "/Library/Developer/Xcode/DerivedData").path

    /// 查询DerivedData
    class func searchList(_ input: String) {
        if DerivedDataPath.directoryExists {
            let paths = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: false).filter({ $0.lastPathComponent != "ModuleCache.noindex" }).sorted(by: <)
            let names = Set(paths.map({ $0.lastPathComponent.components(separatedBy: "-").first! }))
            if paths.isEmpty {
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
                        let path = paths.filter({ ($0.contains("-") && $0.hasPrefix("\(name)-")) || $0.hasPrefix(name) })
                        let subtitle = path.count == 1 ? path.first! : "\(name)同名项目 \(path.count) 个"
                        var item = AlfredItem()
                        item.arg = name
                        item.subtitle = subtitle
                        item.title = name
                        return item
                    }
                    Alfred.flush(items: items)
                }
            } else {
                var items = names.map { name in
                    let path = paths.filter({ ($0.contains("-") && $0.hasPrefix("\(name)-")) || $0.hasPrefix(name) })
                    let subtitle = path.count == 1 ? path.first! : "\(name)同名项目 \(path.count) 个"
                    var item = AlfredItem()
                    item.arg = name
                    item.subtitle = subtitle
                    item.title = name
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
    class func delete(_ input: String) {
        guard !input.isEmpty else { return }
        if input == "Delete All" {
            let paths = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: true)
            paths.forEach({ $0.pathRemove() })
            print("删除所有DerivedData完成")
        } else {
            let name:String
            if let index = input.range(of: "-", options: .backwards) {
                name = String(input[input.startIndex..<index.lowerBound]) + "-"
            } else {
                name = input
            }
            let paths = findFiles(path: DerivedDataPath, isFindSubpaths: false, isFull: true).filter({ $0.lastPathComponent.hasPrefix(name) })
            paths.forEach {
                $0.pathRemove()
            }
            print("删除包含 \(name) 的DerivedData完成")
        }
    }
}
