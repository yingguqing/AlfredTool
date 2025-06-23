//
//  CRC64.swift
//  FictionCrawl
//
//  Created by 影孤清 on 2025/6/10.
//

import Foundation

class CRC64 {
    // ECMA-182
    private let POLY: UInt64 = 0xc96c5795d7870f42
    private var table = [UInt64](repeating: 0, count: 256)
    private var value: UInt64 = ~0 // 初始化为全1

    init() {
        for n in 0..<256 {
            var crc = UInt64(n)
            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = (crc >> 1) ^ POLY
                } else {
                    crc = crc >> 1
                }
            }
            table[n] = crc
        }
    }

    func getValue() -> String {
        let crc = ~value // 最终结果取反
        let first = (crc >> 1) / 5
        let second = crc - first * 10
        return "\(first)\(second)"
    }

    func update(_ b: [UInt8], len: Int) {
        for i in 0..<len {
            update(b[i])
        }
    }

    func update(_ b: UInt8) {
        // 移除了每次更新的取反操作
        value = table[Int((value ^ UInt64(b)) & 0xff)] ^ (value >> 8)
    }

    func update(_ buffer: UnsafeRawBufferPointer) {
        guard let basePtr = buffer.baseAddress else { return }
        let bytePtr = basePtr.assumingMemoryBound(to: UInt8.self)

        // 直接指针访问，不通过load(fromByteOffset:)
        for i in 0..<buffer.count {
            update(bytePtr[i])
        }
    }

    func update(data: Data) {
        data.withUnsafeBytes { rawBuffer in
            update(rawBuffer)
        }
    }
}

extension URL {
    func crc64(progress: ((Double) -> Void)? = nil) -> String {
        guard let stream = InputStream(url: self) else { return "" }
        let crc = CRC64()
        let bufferSize = 1024 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
            stream.close()
        }
        stream.open()
        // 获取文件大小用于进度计算
        let fileSize = Double(fileSize)
        var totalBytesRead = 0
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                let rawBuffer = UnsafeRawBufferPointer(start: buffer, count: bytesRead)
                crc.update(rawBuffer)
                totalBytesRead += bytesRead
                // 计算并报告进度
                let fraction = Double(totalBytesRead) / fileSize
                progress?(fraction)
            }
        }

        return crc.getValue()
    }

    func asyncCRC64() async -> String {
        await withCheckedContinuation { continuation in
            Task {
                let crc = crc64()
                continuation.resume(returning: crc)
            }
        }
    }

    /// 文件大小
    public var fileSize: UInt64 {
        guard isFileURL, let attributes = try? FileManager.default.attributesOfItem(atPath: path), let size = attributes[.size] as? UInt64 else { return 0 }
        return size
    }
}
