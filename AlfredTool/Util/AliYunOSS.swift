//
//  AliYunOSS.swift
//  ProjectConfusion
//
//  Created by 影孤清A on 2023/10/16.
//

import AliyunOSSOSX

/// 阿里云OSS工具
class AliYunOSS {
    var accessKeyId: String = ""
    var accessSecret: String = ""
    var bucketName: String = ""
    var endpoint: String = "https://oss-cn-guangzhou.aliyuncs.com"
    private var putTask: OSSTask<AnyObject>?

    var isValid: Bool {
        !endpoint.isEmpty && !accessKeyId.isEmpty && !accessSecret.isEmpty && !bucketName.isEmpty
    }

    init(accessKeyId: String, accessSecret: String, bucketName:String) {
        self.accessKeyId = accessKeyId
        self.accessSecret = accessSecret
        self.bucketName = bucketName
    }
    
    /// 创建连接
    func client() throws -> OSSClient {
        guard isValid else {
            throw "OSS配置参数不合法"
        }
        /// 生成自签名令牌
        let accessKeyId = self.accessKeyId
        let accessSecret = self.accessSecret
        let credential = OSSCustomSignerCredentialProvider { contentToSign, error in
            let signature = OSSUtil.calBase64Sha1(withData: contentToSign, withSecret: accessSecret)
            guard let signature, !signature.isEmpty else { return nil }
            return "OSS \(accessKeyId):\(signature)"
        }
        guard let credential else {
            throw "获取阿里云OSS授权失败"
        }
        return OSSClient(endpoint: endpoint, credentialProvider: credential)
    }

    /// 上传文件
    /// - Parameters:
    ///   - path: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    func upload(path: String, toPath: String, uploadProgress: ((Double) -> Void)? = nil) throws {
        let data = try Data(contentsOf: path.fileURL)
        try upload(data: data, toPath: toPath, uploadProgress: uploadProgress)
    }

    /// 上传文件
    /// - Parameters:
    ///   - url: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    func upload(url: URL, toPath: String, uploadProgress: ((Double) -> Void)? = nil) throws {
        let data = try Data(contentsOf: url)
        try upload(data: data, toPath: toPath, uploadProgress: uploadProgress)
    }

    /// 上传文件
    /// - Parameters:
    ///   - data: 文件数据
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - uploadProgress: 上传进度回调
    func upload(data: Data, toPath: String, uploadProgress: ((Double) -> Void)? = nil) throws {
        let client = try client()
        let put = OSSPutObjectRequest()
        put.bucketName = bucketName
        put.objectKey = toPath
        put.uploadingData = data
        if let uploadProgress {
            put.uploadProgress = { bytesSend, totalByteSent, totalBytesExpectedToSend in
                // 指定当前上传长度、当前已经上传总长度、待上传的总长度
                uploadProgress(Double(totalByteSent) / Double(totalBytesExpectedToSend) * 100)
            }
        }
        putTask = client.putObject(put)
        putTask?.continue({ task -> OSSTask<AnyObject>? in
            nil
        }).waitUntilFinished()
        if let error = putTask?.error {
            throw error
        }
    }

    /// 获取文件的下载链接
    /// - Parameters:
    ///   - file: 文件路径
    ///   - expirationInterval: 过期时长
    /// - Returns: 下载链接
    func url(file: String, expirationInterval: TimeInterval = 30 * 60) async throws -> String {
        let client = try client()
        let task = client.presignConstrainURL(withBucketName: bucketName, withObjectKey: file, withExpirationInterval: expirationInterval)
        guard let url = task.result as? String else {
            throw "获取文件下载链接失败"
        }
        return url
    }
}
