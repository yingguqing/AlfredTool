//
//  ContentView.swift
//  SearchOpenEdit
//
//  Created by zhouziyuan on 2022/8/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var file: File
    @State private var groupIndex: Int = 0
    @State private var itemId: String? = nil
    @State private var editFileGroup: File.Group?
    @State private var editFileItem: File.Item?

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Picker("文件组", selection: $groupIndex) {
                    ForEach(0 ..< file.groups.count, id: \.self) {
                        Text(self.file.groups[$0].groupName).tag($0)
                    }
                }.onChange(of: groupIndex) { newValue in
                    file.selectGroup(index: newValue)
                }
                Button("新增", action: {
                    file.objectWillChange.send()
                    let group = File.Group(groupName: "未命名")
                    group.isNew = true
                    editFileGroup = group
                    file.groups.append(group)
                })
                Button("编辑", action: {
                    editFileGroup = file.groups[groupIndex]
                })
                Button("删除", action: {
                    file.groups.removeAll(where: { $0.id == file.selectFileGroup.id })
                    if let group = file.groups.first {
                        file.selectFileGroup = group
                    } else {
                        file.selectFileGroup = File.Group(groupName: "未命名")
                        file.selectFileGroup.isNew = true
                        file.groups.append(file.selectFileGroup)
                    }
                })
            }
            HStack {
                Text("默认App：")
                TextField("文件组默认使用此App打开", text: $file.selectFileGroup.defaultApp)
            }
            VStack(spacing: 0) {
                Table(file.selectFileGroup.files, selection: $itemId) {
                    TableColumn("名称") {
                        Text($0.name)
                            .frame(alignment: .leading)
                            .truncationMode(.middle)
                    }
                    TableColumn("路径") {
                        Text($0.path)
                            .truncationMode(.head)
                    }
                }

                .frame(minHeight: 300)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5))
                HStack {
                    Button(action: {
                        guard let item = file.selectFileGroup.files.filter({ $0.id == itemId }).first else { return }
                        editFileItem = item
                    }) {
                        Text("编译文件")
                    }
                    Button(action: {
                        file.objectWillChange.send()
                        let item = File.Item()
                        file.selectFileGroup.files.append(item)
                        editFileItem = item
                    }) {
                        Text("新增文件")
                    }
                    Button(action: {
                        guard let itemId = itemId else { return }
                        file.selectFileGroup.files.removeAll(where: { $0.id == itemId })
                        self.itemId = nil
                    }) {
                        Text("删除文件")
                    }
                    Spacer()
                }
            }
            Button(action: file.save) {
                Text("保存")
                    .frame(maxWidth: .infinity)
            }
            .niceButton(
                foregroundColor: .white,
                backgroundColor: .blue,
                pressedColor: .gray
            )
        }
        .sheet(item: $editFileItem, onDismiss: {
            file.objectWillChange.send()
        }, content: { item in
            FileEditView().environmentObject(item)
        })
        .sheet(item: $editFileGroup, onDismiss: {
            file.objectWillChange.send()
            if file.selectFileGroup.isNew {
                file.groups.removeAll(where: { $0.isNew })
            }
        }, content: { item in
            GroupEditView(groupNames: file.groups.filter { !$0.isNew }.map { $0.groupName }).environmentObject(item)
        })
        .padding(20)
        .frame(width: 480)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
