//
//  AliYunOSS.swift
//  ProjectConfusion
//
//  Created by 影孤清A on 2023/10/16.
//

import AliOSS
import Foundation

/// 阿里云OSS工具
class AliYunOSS {
    init(accessKeyId: String, accessSecret: String, bucketName: String) throws {
        let config = AliOSSConfig(accessKeyId: accessKeyId, accessSecret: accessSecret, bucketName: bucketName)
        try config.use()
    }

    /// 上传文件
    /// - Parameters:
    ///   - path: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    @discardableResult func upload(path: String, toPath: String, uploadProgress: ((Progress) -> Void)? = nil) async throws -> String {
        let data = try Data(contentsOf: path.fileURL)
        return try await upload(data: data, toPath: toPath, uploadProgress: uploadProgress)
    }

    /// 上传文件
    /// - Parameters:
    ///   - url: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    @discardableResult func upload(url: URL, toPath: String, uploadProgress: ((Progress) -> Void)? = nil) async throws -> String {
        let data = try Data(contentsOf: url)
        return try await upload(data: data, toPath: toPath, uploadProgress: uploadProgress)
    }

    /// 上传文件
    /// - Parameters:
    ///   - data: 文件数据
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    @discardableResult func upload(data: Data, toPath: String, uploadProgress: ((Progress) -> Void)? = nil) async throws -> String {
        try await AliOSSFile.Upload(objectKey: toPath, fileData: data).send(progress: uploadProgress)
        return "OSS://\(AliOSSConfig.share.bucketName)/\(toPath)"
    }

    /// 获取文件的下载链接
    /// - Parameters:
    ///   - isPublic: 是否是公开桶
    ///   - file: 文件路径
    ///   - expirationInterval: 过期时长
    /// - Returns: 下载链接
    func url(file: String, expirationInterval: TimeInterval = 30 * 60) async throws -> String {
        let file = AliOSSFile(objectKey: file, expiration: expirationInterval)
        return file.url
    }
}
