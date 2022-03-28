//
//  Util.swift
//  AlfredWorkflow
//
//  Created by zhouziyuan on 2022/3/25.
//

import Foundation
import AppKit

public class AlfredUtil: NSObject {
    
    
    /// 读取plist
    ///
    /// - Parameter path: plist路径
    /// - Returns: 内容
    public static func readPlist(_ path:String) throws -> [String:Any]? {
        guard path.isEmpty == false else { return nil }
        var propertyListForamt = PropertyListSerialization.PropertyListFormat.xml
        if let plistXML = FileManager.default.contents(atPath: path) {
            return try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListForamt) as? [String: Any]
        }
        return nil
    }
    
    public static func local(filename:String) -> String {
        return Bundle.main.bundlePath.appending(pathComponent: filename)
    }
    
    public static var bundleID:String = {
        let path = local(filename: "info.plist")
        guard FileManager.default.fileExists(atPath: path) else {
            log("Could not open \(path)")
            return ""
        }
        do {
            let plist = try readPlist(path)
            return plist?["bundleid"] as? String ?? ""
        } catch {
            log("Error reading \(path): \(error.localizedDescription)")
        }
        return ""
    }()
    
    
    public static func cache(filename:String?=nil) -> String? {
        let c = FileManager.default.cacheDirectory
        var path:String?
        if let c = c {
            path = c.appending(pathComponent: "com.runningwithcrayons.Alfred/Workfow Data/\(bundleID)")
        }
        FileManager.default.createIfNonexistent(path)
        guard let filename = filename else {
            return path
        }

        return path?.appending(pathComponent: filename)
    }
    
    public static func storage(filename:String?=nil) -> String? {
        guard let s = FileManager.default.applicationSupportDirectory else {
            return nil
        }
        let path = s.appending(pathComponent: "Alfred/Workflow Data/\(bundleID)")
        FileManager.default.createIfNonexistent(path)
        guard let filename = filename else {
            return path
        }
        return path.appending(pathComponent: filename)
    }
    
    public class func log(_ str:String) {
        let logloc = local(filename: "framework.log")
        if !FileManager.default.fileExists(atPath: logloc) {
            FileManager.default.createFile(atPath: logloc, contents: str.data(using: .utf8))
        } else {
            guard let data = str.data(using: .utf8) else { return }
            let f = FileHandle(forUpdatingAtPath: logloc)
            let _ = f?.seekToEndOfFile()
            f?.write(data)
            f?.closeFile()
        }
    }
}

extension FileManager {
    func find(director:SearchPathDirectory, inDomain:SearchPathDomainMask, appendingPathComponent append:String?) -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(director, inDomain, true)
        guard let path = paths.first else { return nil }
        guard let append = append, !append.isEmpty else {
            return path
        }
        return path.appending(pathComponent: append)
    }
    
    func createIfNonexistent(_ dir:String?) {
        guard let dir = dir else {
            return
        }

        try? createDirectory(at: URL(fileURLWithPath: dir), withIntermediateDirectories: true)
    }
    
    var applicationSupportDirectory:String? {
        return find(director: .applicationSupportDirectory, inDomain: .userDomainMask, appendingPathComponent: nil)
    }
    
    var cacheDirectory:String? {
        return find(director: .cachesDirectory, inDomain: .userDomainMask, appendingPathComponent: nil)
    }
}

extension String {
    
    func appending(pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}
