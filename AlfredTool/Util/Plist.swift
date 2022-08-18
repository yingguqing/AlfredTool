import Foundation

extension Alfred {
    // Alfred 4的info.plist
    private static let alfredPlist: Plist = .init(path: appBundlePath/"Contents"/"Info.plist")
    // Alfred 4的版本号
    static let build: Int = Int(alfredPlist.get("CFBundleVersion", orElse: "0"))!
    // Alfred 4的bundle id
    static let bundleID: String = alfredPlist.get("CFBundleIdentifier", orElse: "com.runningwithcrayons.Alfred")
    // Alfred的缓存目录
    static let cacheDir: URL = home/"Library"/"Caches"/bundleID
}

class Plist {
    private var dict: [String: Any] = .init()

    init(path: URL, isFlatten:Bool=false) {
        if let plist = NSDictionary(contentsOf: path) as? [String: Any] {
            dict = isFlatten ? flattenJsonObj(arraylessJsonObj: plist) : plist
        } else {
            log("Error: Could not parse '\(path.path)' as a dict.")
        }
    }

    func get<T>(_ key: String) -> T? {
        if let value = dict[key] as? T {
            return value
        } else {
            return nil
        }
    }

    func get<T>(_ key: String, orElse: T) -> T {
        if let value = dict[key] as? T {
            return value
        } else {
            return orElse
        }
    }
}

let info = Plist(path: Alfred.localDir/"info.plist")
/// 获取分支的图标，如果没有就返回icon.png
func itemIcon(title: String) -> String {
    if let objects: [[String: Any]] = info.get("objects") {
        if let uid = objects.filter({
            if let config = $0["config"] as? [String: Any], let t = config["title"] as? String {
                return title == t
            }
            return false
        }).first?["uid"] as? String {
            return "\(uid).png"
        }
    }
    return "icon.png"
}
