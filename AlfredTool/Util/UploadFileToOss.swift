//
//  UploadFileToOss.swift
//  SecurityExam
//
//  Created by zhouziyuan on 2023/1/12.
//

import AlibabacloudOpenApi
import AlibabacloudSts20150401
import AliyunOSSiOS
import Foundation
import Tea
import TeaUtils

/// 上传文件到阿里云OSS
class UploadFileToOss {
    let endpoint = "http://oss-cn-guangzhou.aliyuncs.com"
    let accessKeyId: String
    let accessKeySecret: String
    let securityToken: String
    private(set) var isFinish = false
    private var putTask: OSSTask<AnyObject>?

    init?(accessKeyId: String?, accessKeySecret: String?, securityToken: String?) {
        guard let accessKeyId = accessKeyId, let accessKeySecret = accessKeySecret, let securityToken = securityToken, !accessKeyId.isEmpty, !accessKeySecret.isEmpty, !securityToken.isEmpty else { return nil }
        self.accessKeyId = accessKeyId
        self.accessKeySecret = accessKeySecret
        self.securityToken = securityToken
    }

    /// 创建连接
    func client() async -> OSSClient? {
        let assumeRoleRequest: AlibabacloudSts20150401.AssumeRoleRequest = .init()
        let runtime: TeaUtils.RuntimeOptions = .init([:])
        assumeRoleRequest.roleArn = securityToken
        assumeRoleRequest.roleSessionName = "test"
        let config = AlibabacloudOpenApi.Config([
            "accessKeyId": accessKeyId,
            "accessKeySecret": accessKeySecret
        ])
        config.endpoint = "sts.cn-guangzhou.aliyuncs.com"
        do {
            let roleClient = try AlibabacloudSts20150401.Client(config)
            let roleResponse = try await roleClient.assumeRoleWithOptions(assumeRoleRequest, runtime)
            guard let accessKeyId = roleResponse.body?.credentials?.accessKeyId, let accessKeySecret = roleResponse.body?.credentials?.accessKeySecret, let securityToken = roleResponse.body?.credentials?.securityToken else { return nil }
            let credential = OSSFederationCredentialProvider {
                let token = OSSFederationToken()
                token.tAccessKey = accessKeyId
                token.tSecretKey = accessKeySecret
                token.tToken = securityToken
                return token
            }
            return OSSClient(endpoint: endpoint, credentialProvider: credential)
        } catch {
            return nil
        }
    }

    /// 上传文件
    /// - Parameters:
    ///   - path: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - completionHandler: 结果回调
    func upload(path: String, toPath: String, completionHandler: ((OSSTask<AnyObject>) -> Void)? = nil) async {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        await upload(data: data, toPath: toPath, completionHandler: completionHandler)
    }

    /// 上传文件
    /// - Parameters:
    ///   - url: 文件绝对路径
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - completionHandler: 结果回调
    func upload(url: URL, toPath: String, completionHandler: ((OSSTask<AnyObject>) -> Void)? = nil) async {
        guard let data = try? Data(contentsOf: url) else { return }
        await upload(data: data, toPath: toPath, completionHandler: completionHandler)
    }

    /// 上传文件
    /// - Parameters:
    ///   - data: 文件数据
    ///   - toPath: OSS上的保存路径，前面不带/
    ///   - completionHandler: 结果回调
    func upload(data: Data, toPath: String, completionHandler: ((OSSTask<AnyObject>) -> Void)? = nil) async {
        defer { isFinish = true }
        guard let client = await client() else { return }
        let put = OSSPutObjectRequest()
        put.bucketName = "yingguqing"
        put.objectKey = toPath
        put.uploadingData = data
/*
        put.uploadProgress = { bytesSend, totalByteSent, totalBytesExpectedToSend in
            print("\(bytesSend)    \(totalByteSent)    \(totalBytesExpectedToSend)")
        }
*/
        putTask = client.putObject(put)
        putTask?.continue({ task -> OSSTask<AnyObject>? in
            completionHandler?(task)
            return nil
        })
        putTask?.waitUntilFinished()
    }
}
