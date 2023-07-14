//
//  DistinctProvisionProfile.swift
//  DistinctProvisionProfile
//
//  Created by zhouziyuan on 2022/8/25.
//

import Cocoa

class DistinctProvisionProfile {
    let ProvisioningProfilesPath = (Alfred.home / "Library/MobileDevice/Provisioning Profiles").path
    
    /// 描述文件中的证书信息
    struct DeveloperCertificate {
        let name: String // 证书名称：iPhone Developer: Created via API (G7X5J84AUC)
        let teamID: String
        let expires: Date? // 证书过期时间
        
        /// 证书是否过期
        var isExpire:Bool {
            guard let date = expires else { return false }
            return Date() > date
        }
    }
    
    struct ProvisioningProfile {
        let path: String
        let name: String
        let applicationIdentifier: String
        let created: Date
        let expires: Date
        let bundleId: String
        let teamID: String
        let platforms: [String]
        let rawXML: String
        let devices: [String]
        let certificates: [DeveloperCertificate]
        
        /// 描述文件里的证书，本地是否存在
        func isContain(teamIds:[String]) -> Bool {
            let cers = certificates.filter({ teamIds.contains($0.teamID) })
            return !cers.isEmpty
        }
        
        /// 证书是否过期
        func isExpire(teamIds:[String]) -> Bool {
            let date = Date()
            // 描述文件自身过期
            guard date < expires else { return true }
            // 描述文件里包含的所有本地证书都过期了
            let cers = certificates.filter({ teamIds.contains($0.teamID) && !$0.isExpire })
            return !cers.isEmpty
        }
    }
    
    func run() {
        let allTeamId = allCodeSigningCert()
        // 获取本地所有的描述文件
        let files = findFiles(path: ProvisioningProfilesPath, filterTypes: ["mobileprovision"]).compactMap { ProvisioningProfile(path: $0) }
        var profileDic = [String: [ProvisioningProfile]]()
        var noTemeIdCount = 0
        var expireCount = 0
        var sameCount = 0
        // 通过标识获取同一个证书的不同版本
        files.forEach {
            // 描述文件有相应证书
            if $0.isContain(teamIds: allTeamId) {
                let id = "\($0.applicationIdentifier)-\($0.name)"
                var list = profileDic[id] ?? []
                list.append($0)
                profileDic.updateValue(list, forKey: id)
            } else if ($0.isExpire(teamIds: allTeamId)) {
                // 描述文件过期、或里面的本地证书全部过期
                try? FileManager.default.removeItem(atPath: $0.path)
                expireCount += 1
            } else {
                // 描述文件没有证书时，直接删除
                 try? FileManager.default.removeItem(atPath: $0.path)
                noTemeIdCount += 1
            }
        }
        // 删除相同证书的其他版本，只保留最新创建的描述文件
        profileDic.values.forEach {
            guard $0.count > 1 else { return }
            // 最新创建的排在最前面
            let list = $0.sorted(by: { $0.created > $1.created })
            // 只保留最新创建的，其他的全部删除
            list.dropFirst().forEach {
                 try? FileManager.default.removeItem(atPath: $0.path)
                sameCount += 1
            }
        }
        var msg = "清除描述文件"
        if noTemeIdCount > 0 {
            msg += "\n无证书：\(noTemeIdCount)"
        }
        if expireCount > 0 {
            msg += "\n证书过期：\(expireCount)"
        }
        if sameCount > 0 {
            msg += "\n相同文件：\(sameCount)"
        }
        if noTemeIdCount + sameCount + sameCount == 0 {
            msg += ": 无"
        }
        print(msg)
    }
    
    /// 获取本地所有证书的teamId
    private func allCodeSigningCert() -> [String] {
        let result = Process.execute("/usr/bin/security", arguments: ["find-identity", "-v", "-p", "codesigning"])
        guard !result.output.isEmpty else { return [] }
        let regex = Regex(#"\(([A-Z0-9]{5,})\)""#)
        let ids = regex.matches(in: result.output).filter({ !$0.captures.isEmpty }).flatMap({ $0.captures }).compactMap({ $0 })
        return Array(Set(ids))
    }
}

extension DistinctProvisionProfile.ProvisioningProfile {
    init?(path: String) {
        let taskOutput = Process.execute("/usr/bin/security", arguments: ["cms", "-D", "-i", path])
        guard taskOutput.status == 0 else { return nil }
        if let xmlIndex = taskOutput.output.range(of: "<?xml") {
            self.rawXML = String(taskOutput.output[xmlIndex.lowerBound...])
        } else {
            self.rawXML = taskOutput.output
        }
        guard let result = try? PropertyListSerialization.propertyList(from: Data(rawXML.utf8), options: PropertyListSerialization.MutabilityOptions(), format: nil) as? [String: Any] else { return nil }
        let expirationDate = result["ExpirationDate"] as? Date
        let creationDate = result["CreationDate"] as? Date
        let name = result["Name"] as? String
        let platforms = result["Platform"] as? [String]
        /// 获取证书信息
        let certificateDatas = result["DeveloperCertificates"] as? [Data] ?? []
        self.certificates = certificateDatas.compactMap({ DistinctProvisionProfile.DeveloperCertificate(data: $0) })
        let entitlements = result["Entitlements"] as? [String: Any]
        let teamId = entitlements?["com.apple.developer.team-identifier"] as? String
        let applicationIdentifier = entitlements?["application-identifier"] as? String
        guard let expirationDate = expirationDate, let creationDate = creationDate, let name = name, let platforms = platforms, let applicationIdentifier = applicationIdentifier, let teamId = teamId, let periodIndex = applicationIdentifier.firstIndex(of: ".") else { return nil }
        self.devices = result["ProvisionedDevices"] as? [String] ?? []
        self.path = path
        self.expires = expirationDate
        self.created = creationDate
        self.platforms = platforms
        self.bundleId = String(applicationIdentifier[applicationIdentifier.index(periodIndex, offsetBy: 1)...])
        self.teamID = teamId
        self.name = name
        self.applicationIdentifier = applicationIdentifier
    }
}

extension DistinctProvisionProfile.DeveloperCertificate {
    
    init?(data: Data) {
        guard let cfData = CFDataCreate(kCFAllocatorDefault, (data as NSData).bytes, data.count), let certificateRef = SecCertificateCreateWithData(nil, cfData) else { return nil }
        guard let summary = SecCertificateCopySubjectSummary(certificateRef) as? String else { return nil }
        var error: Unmanaged<CFError>?
        guard let valuesDict = SecCertificateCopyValues(certificateRef, [kSecOIDInvalidityDate] as? CFArray, &error) as? [CFString: AnyObject] else { return nil }
        guard let invalidityDateDictionaryRef = valuesDict[kSecOIDInvalidityDate] as? [CFString: AnyObject] else { return nil }
        guard let invalidityRef = invalidityDateDictionaryRef[kSecPropertyKeyValue] else { return nil }
        self.name = summary
        let regex = Regex(#"\(([A-Z0-9]{5,})\)"#)
        let teamID = regex.matches(in: summary).filter({ !$0.captures.isEmpty }).flatMap({ $0.captures }).compactMap({ $0 }).first ?? ""
        self.teamID = teamID
        if let invalidity = invalidityRef as? Date {
            self.expires = invalidity
        } else {
            let string = invalidityRef.description ?? ""
            let invalidityDateFormatter = DateFormatter()
            invalidityDateFormatter.locale = Locale(identifier: "zh_CN")
            invalidityDateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
            if let invalidityDate = invalidityDateFormatter.date(from: string) {
                self.expires = invalidityDate
            } else {
                self.expires = nil
            }
        }
    }
}
