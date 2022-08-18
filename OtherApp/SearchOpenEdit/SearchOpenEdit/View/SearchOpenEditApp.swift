//
//  SearchOpenEditApp.swift
//  SearchOpenEdit
//
//  Created by zhouziyuan on 2022/8/1.
//

import SwiftUI

@main
struct SearchOpenEditApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var file: File = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(file)
                .onOpenURL { url in
                    file.objectWillChange.send()
                    file.reload(path: url.path)
                }
                .onAppear {
#if DEBUG
                    guard let path = Bundle.main.path(forResource: "UserFileInfo.json", ofType: nil) else { exit(1) }
                    file.objectWillChange.send()
                    file.reload(path: path)
#endif
                }
        }
        
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func application(_: NSApplication, openFile filename: String) -> Bool {
        print("openning file \(filename)")

        // You must determine if filename points to a file or folder

        // Now do your things...

        // Return true if your app opened the file successfully, false otherwise
        let path = "/Users/zhouziyuan/Desktop/abcdef"
        path.createFilePath()
        return true
    }

    // 关闭界面时,true为同时关闭程序，false为最小化程序
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
