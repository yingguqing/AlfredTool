//
//  File.swift
//  SearchOpenEdit
//
//  Created by zhouziyuan on 2022/8/1.
//

import Cocoa

class File: ObservableObject {
    @Published var groups: [File.Group] = []
    @Published var selectFileGroup: File.Group = .init(groupName: "")

    private var savePath: String = ""

/*
    init() {
        #if DEBUG
        guard let path = Bundle.main.path(forResource: "UserFileInfo.json", ofType: nil) else { exit(1) }
        self.savePath = path.deletingLastPathComponent / (path.fileNameWithoutExtension + "1.json")
        #else
        let arguments = ProcessInfo().arguments
        print(arguments)
        guard arguments.count > 1 else { exit(1) }
        let path = arguments[1]
        self.savePath = path
        #endif
        do {
            let str = try String(contentsOfFile: path)
            guard let json = str.toDictionary else { exit(1) }
            let app: [String: String] = json["App"] as? [String: String] ?? [:]
            self.groups = json.filter { $0.0 != "App" }.map { Group(groupName: $0.0, files: $0.1 as? [[String: String]], defaultApp: app[$0.0]) }.sorted(by: { $0.groupName > $1.groupName })
        } catch {
            self.groups = []
        }
        if groups.isEmpty {
            groups.append(File.Group(groupName: "新增文件组"))
        }
    }
*/

    func reload(path:String) {
        self.savePath = path
        do {
            let str = try String(contentsOfFile: path)
            guard let json = str.toDictionary else { return }
            let app: [String: String] = json["App"] as? [String: String] ?? [:]
            self.groups = json.filter { $0.0 != "App" }.map { Group(groupName: $0.0, files: $0.1 as? [[String: String]], defaultApp: app[$0.0]) }.sorted(by: { $0.groupName > $1.groupName })
        } catch {
            self.groups = []
        }
        if groups.isEmpty {
            groups.append(File.Group(groupName: "新增文件组"))
        }
        selectGroup(index: 0)
    }
    
    func selectGroup(index: Int) {
        if index >= 0, index < groups.count {
            selectFileGroup = groups[index]
        } else {
            selectFileGroup = File.Group(groupName: "")
        }
    }

    func save() {
        let app = groups.filter { !$0.defaultApp.isEmpty }.map { ($0.groupName, $0.defaultApp) }
        var json: [String: Any] = ["App": Dictionary(uniqueKeysWithValues: app)]
        groups.forEach {
            guard !$0.groupName.isEmpty else { return }
            json.updateValue($0.files.compactMap { $0.json }, forKey: $0.groupName)
        }
        do {
            try json.jsonString?.write(toFile: savePath, atomically: true, encoding: .utf8)
        } catch {
            print("保存文件失败：\(error.localizedDescription)")
        }
    }
}

extension File {
    class Group: ObservableObject, Identifiable {
        let id: String = UUID().uuidString
        // 默认app
        @Published var defaultApp: String = ""
        @Published var groupName: String = ""
        @Published var files: [File.Item] = []
        
        var isNew = false

        init(groupName: String, files: [[String: String]]? = nil, defaultApp: String? = nil) {
            self.defaultApp = defaultApp ?? ""
            self.groupName = groupName
            self.files = files?.compactMap { Item(json: $0) } ?? []
        }
    }
}

extension File {
    class Item: ObservableObject, Identifiable {
        let id: String = UUID().uuidString
        @Published var name: String = "双击编辑"
        @Published var path: String = ""
        // 查询的其他关键词
        @Published var search: String = ""
        // 使用其他App打开，为空使用默认app
        @Published var app: String = ""
        // 用于记录编辑前的值
        var temp: File.Item?

        convenience init?(json: [String: String]) {
            guard let path = json["path"], path.fileExists || path.directoryExists else { return nil }
            self.init()
            self.path = path
            self.name = json["name"] ?? ""
            if name.isEmpty {
                self.name = path.fileNameWithoutExtension
            }
            self.search = json["search"] ?? ""
            self.app = json["app"] ?? ""
        }

        var json: [String: String]? {
            guard path.fileExists || path.directoryExists else { return nil }
            var json = [
                "name": name,
                "path": path,
                "search": search
            ]
            if name == path.fileNameWithoutExtension {
                json.updateValue("", forKey: "name")
            }
            guard !app.isEmpty else { return json }
            json.updateValue(app, forKey: "app")
            return json
        }

        func saveTempValue() {
            guard temp == nil else { return }
            temp = Item()
            temp?.setValue(self)
        }

        func cancelEdit() {
            guard let temp = temp else { return }
            setValue(temp)
        }

        func setValue(_ item: Item) {
            name = item.name
            path = item.path
            search = item.search
            app = item.app
            if name.isEmpty {
                name = path.fileNameWithoutExtension
            }
        }
    }
}

extension Dictionary where Key == String {
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }

    var jsonString: String? {
        guard let data = jsonData else { return nil }
        return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
    }
}
