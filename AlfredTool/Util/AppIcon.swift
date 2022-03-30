//
//  AppIconGrabber.swift
//  EnumWindows
//
//  Created by Igor Mandrigin on 2017-02-22.
//  Copyright © 2017 Igor Mandrigin. All rights reserved.
//

import Foundation
import AppKit

public struct AppIcon {
    
    let appName : String
    
    public init(appName: String) {
        self.appName = appName
    }
    
    public func saveIcon(image:NSImage?) {
        guard let data = image?.tiffRepresentation else {
            return
        }
        let representation = NSBitmapImageRep(data: data)
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor : 1.0]
        let newData = representation?.representation(using: .png, properties: properties)
        try? newData?.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
    
    public var path : String {
        return self.pathInternal ?? ""
    }
    
    private var pathInternal : String? {
        let appPath = self.appName | { NSWorkspace.shared.fullPath(forApplication: $0) }
        
        guard var iconFileName = appPath | { Bundle(path: $0) } | { $0.infoDictionary?["CFBundleIconFile"] } | { $0 as? String } else {
            return nil
        }
        
        if !iconFileName.hasSuffix(".icns") {
            iconFileName.append(".icns")
        }
        
        let url = appPath | { URL(fileURLWithPath: $0) } | { $0.appendingPathComponent("Contents/Resources/\(iconFileName)") }
        
        return url?.path ?? nil
    }
}


/**
 * Just having fun with the pipelining
 */
precedencegroup PipelinePrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
}
infix operator | : PipelinePrecedence

func | <A, B> (lhs : A?, rhs : (A) -> B?) -> B? {
    guard let l = lhs else {
        return nil
    }
    
    return rhs(l)
}
