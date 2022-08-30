//
//  DistinctProvisionProfile.swift
//  DistinctProvisionProfile
//
//  Created by zhouziyuan on 2022/8/25.
//

import Cocoa

class DistinctProvisionProfile {
    
    let ProvisioningProfilesPath = (Alfred.home / "Library/MobileDevice/Provisioning Profiles").path
    
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
    }
    
    func run() {
        let allTeamId = allCodeSigningCert()
        // 获取本地所有的描述文件
        let files = findFiles(path: ProvisioningProfilesPath, filterTypes: ["mobileprovision"]).compactMap { ProvisioningProfile(path: $0) }
        var profileDic = [String:[ProvisioningProfile]]()
        // 通过标识获取同一个证书的不同版本
        files.forEach {
            // 描述文件有相应证书
            if allTeamId.contains($0.teamID) {
                let id = "\($0.applicationIdentifier)-\($0.name)"
                var list = profileDic[id] ?? []
                list.append($0)
                // 最新创建的排在最前面
                list.sort(by: { $0.created.timeIntervalSince1970 > $1.created.timeIntervalSince1970 })
                profileDic.updateValue(list, forKey: id)
            } else {
                // 描述文件没有证书时，直接删除
                try? FileManager.default.removeItem(atPath: $0.path)
            }
        }
        // 删除相同证书的其他版本，只保留最新创建的描述文件
        profileDic.values.forEach {
            guard $0.count > 1 else { return }
            let removeFiles = Array($0.dropFirst())
            removeFiles.forEach {
                try? FileManager.default.removeItem(atPath: $0.path)
            }
        }
        print("清除重复描述文件完成")
    }
    
    /// 获取本地所有证书的teamId
    private func allCodeSigningCert() -> Set<String> {
        let result = Process.execute("/usr/bin/security", arguments: ["find-identity", "-v", "-p", "codesigning"])
        guard !result.output.isEmpty else { return [] }
        let regex = try! Regex("\\(([A-Z0-9]{5,})\\)\"")
        let ids = regex.matches(in: result.output).filter { !$0.captures.isEmpty }.flatMap { $0.captures }.compactMap { $0 }
        return Set(ids)
    }
    
    /// 获取本地所有的描述文件
    private func allProfiles() -> [ProvisioningProfile] {
        let files = findFiles(path: ProvisioningProfilesPath, filterTypes: ["mobileprovision"]).compactMap { ProvisioningProfile(path: $0) }
        print(files.map { $0.name }.joined(separator: ","))
        
        return []
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
