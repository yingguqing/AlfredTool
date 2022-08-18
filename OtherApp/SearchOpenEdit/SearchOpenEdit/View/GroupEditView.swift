//
//  GroupEditView.swift
//  SearchOpenEdit
//
//  Created by zhouziyuan on 2022/8/1.
//

import SwiftUI

struct GroupEditView: View {
    @Environment (\.presentationMode) var presentationMode
    @EnvironmentObject var group:File.Group
    @State var msg:String = ""
    // 已存在的文件组key
    private var groupNames:[String]
    @State private var tempGroupName:String?
    
    init(groupNames:[String]) {
        self.groupNames = groupNames
    }
    
    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading) {
                TextField("文件组的Key", text: $group.groupName)
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            VStack {
                Button(action: {
                    if group.groupName.isEmpty {
                        msg = "文件组key不能为空"
                    } else if groupNames.contains(group.groupName) {
                        msg = "\(group.groupName) 已存在"
                    } else {
                        msg = ""
                        presentationMode.wrappedValue.dismiss()
                    }
                    group.isNew = false
                }) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                }
                .niceButton(
                    foregroundColor: .white,
                    backgroundColor: .blue,
                    pressedColor: .blue
                )
                Button(action: {
                    group.groupName = tempGroupName ?? ""
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)
                .niceButton(
                    foregroundColor: .white,
                    backgroundColor: .red,
                    pressedColor: .red
                )
            }
        }
        .onAppear(perform: {
            guard tempGroupName == nil  else { return }
            tempGroupName = group.groupName
        })
        .frame(minWidth: 500)
        .padding(20)
    }
}

