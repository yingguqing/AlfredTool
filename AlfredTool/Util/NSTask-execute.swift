//
//  NSTask-execute.swift
//  AppSigner
//
//  Created by Daniel Radtke on 11/3/15.
//  Copyright © 2015 Daniel Radtke. All rights reserved.
//

import Foundation

struct AppSignerTaskOutput {
    var output: String
    var status: Int32
    init(status: Int32, output: String) {
        self.status = status
        self.output = output
    }
}

private extension Process {
    func launchSyncronous(process: ((String) -> Void)? = nil) -> AppSignerTaskOutput {
        self.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        self.standardOutput = pipe
        self.standardError = pipe
        let pipeFile = pipe.fileHandleForReading
        self.launch()
        
        var msgs = String()
        while self.isRunning {
            if let msg = String(data: pipeFile.availableData, encoding: .utf8) {
                process?(msg)
                msgs.append(msg)
            }
        }
        
        pipeFile.closeFile()
        self.terminate()
        
        return AppSignerTaskOutput(status: self.terminationStatus, output: msgs)
    }
    
    func execute(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil) -> AppSignerTaskOutput {
        self.launchPath = launchPath
        if arguments != nil {
            self.arguments = arguments
        }
        if workingDirectory != nil {
            self.currentDirectoryPath = workingDirectory!
        }
        return self.launchSyncronous()
    }
    
    func executeAsync(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil, process: ((String) -> Void)? = nil, complete: ((AppSignerTaskOutput) -> Void)?) {
        self.launchPath = launchPath
        self.arguments = arguments
        /*
         if let oldPath = ProcessInfo.processInfo.environment["PATH"] {
             self.environment = [
                 "PATH": oldPath.appending(":/Users/xiankaizheng/.rvm/rubies/ruby-2.5.1/bin")
             ]
         }
         */
        if workingDirectory != nil {
            self.currentDirectoryPath = workingDirectory!
        }
        
        DispatchQueue.global(qos: .background).async {
            let task = self.launchSyncronous(process: { msg in
                DispatchQueue.main.async {
                    process?(msg)
                }
            })
            DispatchQueue.main.async {
                complete?(task)
            }
        }
    }
}

extension Process {
    static func launchSyncronous(process: ((String) -> Void)? = nil) -> AppSignerTaskOutput {
        return Process().launchSyncronous(process: process)
    }
    
    static func execute(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil) -> AppSignerTaskOutput {
        return Process().execute(launchPath, workingDirectory: workingDirectory, arguments: arguments)
    }
    
    static func executeAsync(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil, process: ((String) -> Void)? = nil, complete: ((AppSignerTaskOutput) -> Void)?) {
        Process().executeAsync(launchPath, workingDirectory: workingDirectory, arguments: arguments, process: process, complete: complete)
    }
}
