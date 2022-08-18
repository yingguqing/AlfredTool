//
//  FileEditView.swift
//  SearchOpenEdit
//
//  Created by zhouziyuan on 2022/8/1.
//

import SwiftUI

struct FileEditView: View {
    @Environment (\.presentationMode) var presentationMode
    @EnvironmentObject var item:File.Item
    @State var msg:String = ""
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("显示名称", text: $item.name)
            TextField("文件路径", text: $item.path)
            TextField("查询关键词", text: $item.search)
            VStack(alignment: .leading) {
                TextField("指定使用app打开", text: $item.app)
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            VStack {
                Button(action: {
                    if item.path.fileExists || item.path.directoryExists {
                        item.temp = nil
                        presentationMode.wrappedValue.dismiss()
                        msg = ""
                    } else {
                        msg = "文件路径不存在"
                    }
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
                    item.cancelEdit()
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
        .onAppear(perform: item.saveTempValue)
        .frame(minWidth: 500)
        .padding(20)
    }
}

struct FileEditView_Previews: PreviewProvider {
    static var previews: some View {
        FileEditView()
            .environmentObject(File.Item())
    }
}
