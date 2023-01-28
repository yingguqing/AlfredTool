import Foundation

extension URL {
    static func /(parent: URL, child: String) -> URL {
        parent.appendingPathComponent(child)
    }

    func subDirs() -> [URL] {
        let fs = FileManager.default
        guard hasDirectoryPath else {
            log("Error: couldn't get contents of directory: \(path)")
            return []
        }
        if let dirs = try? fs.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil
        ).filter(\.hasDirectoryPath) {
            return dirs
        } else {
            log("Error: couldn't get contents of directory: \(path)")
            return []
        }
    }
}

extension FileManager {
    func exists(_ url: URL) -> Bool {
        fileExists(atPath: url.path)
    }
}

extension Array {
    func value(index: Int) -> Element? {
        guard self.count > index else { return nil }
        return self[index]
    }
}

func log(_ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    let basename = filename.split(separator: "/").last ?? ""
    NSLog("[\(basename):\(line) \(function)] \(message)")
}

func jsonObj(contentsOf filepath: URL) -> [String: Any]? {
    do {
        let data = try Data(contentsOf: filepath)
        let parsedJson = try JSONSerialization.jsonObject(with: data)
        if let json = parsedJson as? [String: Any] {
            return json
        }
    } catch {
        log("\(error)")
        log("Error: Couldn't read JSON object from: \(filepath.path)")
    }
    return nil
}

/// 获取用户配置
/// - Parameter key: 配置项
/// - Returns: 内容
func userConfig<T>(_ key: String, fileName: String = "user_config.json") -> T? {
    let path = Alfred.localDir / fileName
    guard let config = jsonObj(contentsOf: path) else {
        return nil
    }
    return config[key] as? T
}

/// 保存用户配置
/// - Parameters:
///   - key: 配置key
///   - value: 配置内容
func saveUserConfig(key: String, value: Any, fileName: String = "user_config.json") {
    let path = Alfred.localDir / fileName
    var config = jsonObj(contentsOf: path) ?? [String: Any]()
    config[key] = value
    let data = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
    try? data?.write(to: path, options: .atomic)
}

/// Flatten a JSON object (ignoring any arrays)
///
/// ```
/// Example input:
/// {
///   "a": {
///     "b": 9,
///     "c": "hello
///   },
///   "d": 4.2,
/// }
///
/// Example output:
/// {
///   "a-b": 9,
///   "a-c": "hello,
///   "d": 4.2
/// }
/// ```
/// - Parameters:
///   - arraylessJsonObj: JSON object that's known to not have arrays
///   - keySeparator: string that joins keys at various levels
/// - Returns: a single-level JSON object
func flattenJsonObj(arraylessJsonObj: [String: Any], keySeparator: String = "-") -> [String: Any] {
    var flattened = [String: Any]()
    for (key, value) in arraylessJsonObj {
        switch value {
        case let obj as [String: Any]:
            let flatObj = flattenJsonObj(
                arraylessJsonObj: obj,
                keySeparator: keySeparator
            )
            for (innerKey, value) in flatObj {
                flattened[key + keySeparator + innerKey] = value
            }
        case let arr as [Any]:
            log("Error: encountered \(arr) while flattening JSON.")
        default:
            flattened[key] = value
        }
    }
    return flattened
}

/// 获取指定文件夹下符合扩展名要求的所有文件名
/// - parameter path: 文件夹路径
/// - parameter filterTypes: 扩展名过滤类型(注：大小写敏感)
/// - parameter isFindSubpaths: 是否递归查找
/// - parameter isFull: 是否拼接成完整目录
/// - returns: 所有文件名数组
func findFiles(path: String, filterTypes: [String] = [], isFindSubpaths: Bool = true, isFull: Bool = true) -> [String] {
    do {
        var files = [String]()
        if isFindSubpaths { // 递归查找
            if let array = FileManager.default.subpaths(atPath: path)?.filter({ !$0.lastPathComponent.hasPrefix(".") }) {
                files = array
            }
        } else {
            files = try FileManager.default.contentsOfDirectory(atPath: path).filter({ !$0.lastPathComponent.hasPrefix(".") })
        }
        if isFull {
            files = files.map { path / $0 }
        }
        guard filterTypes.count > 0 else { return files }
        return files.filter { return filterTypes.contains($0.pathExtension) }
    } catch {}
    return []
}
