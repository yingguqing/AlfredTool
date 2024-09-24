//
//  NSTask-execute.swift
//  AppSigner
//
//  Created by Daniel Radtke on 11/3/15.
//  Copyright © 2015 Daniel Radtke. All rights reserved.
//

import Foundation

struct TaskOutput {
    var output: String
    var status: Int32
    var isSuccess: Bool {
        self.status == 0
    }
    init(status: Int32, output: String) {
        self.status = status
        self.output = output
    }
}

private extension Process {
    func execute(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil, environment: String? = nil, process: ((String) -> Void)? = nil, isWriteLog: Bool = true) -> TaskOutput {
        // 临时环境变量
        if let environment, !environment.isEmpty {
            self.environment = [
                "PATH": ProcessInfo.processInfo.environment["PATH"]?.appending(":\(environment)") ?? environment
            ]
        }

        if let workingDirectory, !workingDirectory.isEmpty {
            currentDirectoryPath = workingDirectory
        }

        self.launchPath = launchPath
        if let arguments, !arguments.isEmpty {
            self.arguments = arguments
        }
        standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        standardOutput = pipe
        standardError = pipe
        let pipeFile = pipe.fileHandleForReading
        launch()
        var msgs = String()
        while isRunning {
            if let msg = String(data: pipeFile.availableData, encoding: .utf8) {
                process?(msg)
                msgs.append(msg)
            }
        }

        pipeFile.closeFile()
        terminate()
        return TaskOutput(status: self.terminationStatus, output: msgs)
    }
}

extension Process {
    @discardableResult static func execute(_ launchPath: String, workingDirectory: String? = nil, arguments: [String]? = nil) -> TaskOutput {
        return Process().execute(launchPath, workingDirectory: workingDirectory, arguments: arguments)
    }
}
