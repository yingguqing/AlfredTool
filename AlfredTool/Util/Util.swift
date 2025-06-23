//
//  Util.swift
//  AlfredTool
//  
//  Created by 影孤清 on 2025/6/23.
//  
    
import Foundation

/// 获取设备的UUID
let DeviceUUID: String = {
    let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    defer { IOObjectRelease(platformExpert) }
    if platformExpert > 0, let uuid = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() as? String {
        return uuid
    }
    fatalError("获取设备UUID失败")
}()
