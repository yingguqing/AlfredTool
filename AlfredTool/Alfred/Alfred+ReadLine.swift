//
//  Alfred+ReadLine.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/29.
//

import Foundation

extension Alfred {
    @discardableResult
    public static func readLine(_ options: [Option]) -> [String] {
        let cli = CommandLine()
        cli.addOptions(options)

        do {
            try cli.parse(strict: true)
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        return cli.argumentValues
    }

    @discardableResult
    public static func readLine(_ option: Option...) -> [String] {
        let cli = CommandLine()
        cli.addOptions(option)

        do {
            try cli.parse(strict: true)
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        return cli.argumentValues
    }
}
