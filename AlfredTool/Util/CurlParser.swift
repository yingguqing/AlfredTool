import Foundation

public enum CurlOption {
    case url(String)
    case data(String)
    case form(_ key: String, _ value: String)
    case header(_ key: String, _ value: String)
    case referer(String)
    case userAgent(String)
    case user(_ user: String, _ password: String?)
    case requestMethod(String)
}

fileprivate enum Lexer {
    static func tokenize(_ str: String) -> [String] {
        let str = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var slices = [String]()
        let scanner = Scanner(string: str)
        scanner.charactersToBeSkipped = nil
        var buffer = ""

        while scanner.isAtEnd == false {
            let result = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: " \n\"\'"))
            if result == nil {
                scanner.currentIndex = str.index(after: scanner.currentIndex)
            }
            if scanner.isAtEnd {
                buffer += result ?? ""
                slices.append(buffer)
                break
            }

            let lastChar = String(str[scanner.currentIndex])
            if lastChar == "\"" || lastChar == "\'" {
                let quote = lastChar
                buffer += result ?? ""
                scanner.currentIndex = str.index(after: scanner.currentIndex)
                while true {
                    if let scannedString = scanner.scanUpToString(quote) {
                        buffer.append(scannedString)
                        if scanner.isAtEnd {
                            if !buffer.isEmpty {
                                slices.append(buffer)
                            }
                            buffer = ""
                            break
                        }
                        if scannedString[scannedString.index(before: scannedString.endIndex)] != "\\" {
                            // Find matching quote mark.
                            scanner.currentIndex = str.index(after: scanner.currentIndex)
                            if let _ = scanner.scanCharacters(from: CharacterSet(charactersIn: " \n")) {
                                if !buffer.isEmpty {
                                    slices.append(buffer)
                                    buffer = ""
                                }
                            }
                            break
                        } else {
                            // The quote mark is escaped. Continue.
                            scanner.currentIndex = str.index(after: scanner.currentIndex)
                            buffer.remove(at: buffer.index(before: buffer.endIndex))
                            buffer.append(quote)
                        }
                    } else {
                        if !buffer.isEmpty {
                            slices.append(buffer)
                            buffer = ""
                        }
                        break
                    }
                }
                if scanner.isAtEnd {
                    if !buffer.isEmpty {
                        slices.append(buffer)
                        buffer = ""
                    }
                    break
                }
            } else {
                buffer += result ?? ""
                if !buffer.isEmpty {
                    slices.append(buffer)
                }
                buffer = ""
            }
        }
        return slices
    }

    fileprivate static func handleShortCommands(_ tokens: [String], _ index: Int, _ token: String, _ options: inout [CurlOption]) {
        let nextToken = tokens[index]
        switch token {
        case "-d":
            options.append(.data(nextToken))
        case "-F":
            let components = nextToken.components(separatedBy: "=")
            if components.count < 2 {
                return
            }
            options.append(.form(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1]))
        case "-H":
            let components = nextToken.components(separatedBy: ":")
            if components.count < 2 {
                return
            }
            options.append(.header(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)))
        case "-e":
            options.append(.referer(nextToken))
        case "-A":
            options.append(.userAgent(nextToken))
        case "-X":
            options.append(.requestMethod(nextToken))
        case "-u":
            let components = nextToken.components(separatedBy: ":")
            if components.count >= 2 {
                options.append(.user(components[0], components[1]))
            } else {
                options.append(.user(components[0], nil))
            }
        default:
            return
        }
    }

    fileprivate static func handleLongCommands(_ tokens: [String], _ index: Int, _ token: String, _ options: inout [CurlOption]) {
        let components: [String]
        if !token.contains("=") {
            components = [token, tokens[index]]
        } else {
            components = token.components(separatedBy: "=")
        }
        switch components[0] {
        case "--data", "--data-binary":
            if components.count < 2 {
                return
            }
            options.append(.data(components[1]))
        case "--form", "-form-string":
            if components.count < 3 {
                return
            }
            options.append(.form(components[1], components[2]))
        case "--header":
            if components.count < 2 {
                return
            }
            let keyValue = components[1].components(separatedBy: ":")
            if keyValue.count < 2 {
                return
            }
            options.append(.header(keyValue[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), keyValue[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)))
        case "--referer":
            if components.count < 2 {
                return
            }
            options.append(.referer(components[1]))
        case "--user-agent":
            if components.count < 2 {
                return
            }
            options.append(.userAgent(components[1]))
        case "--request":
            if components.count < 2 {
                return
            }
            options.append(.requestMethod(components[1]))
        case "--user":
            if components.count < 2 {
                return
            }
            let userPassword = components[1].components(separatedBy: ":")
            if userPassword.count >= 2 {
                options.append(.user(userPassword[0], userPassword[1]))
            } else {
                options.append(.user(userPassword[0], nil))
            }
        case "--compressed":
            if components.count < 2 {
                return
            }
            options.append(.url(components[1]))

        default:
            return
        }
    }

    static func convertTokensToOptions(_ tokens: [String]) -> [CurlOption] {
        switch tokens.first {
        case "curl": break
        default:
            print("Your command should start with \"curl\".")
            return []
        }
        guard tokens.count >= 2 else {
            print("You did not specific a URL in your command.")
            return []
        }
        var options = [CurlOption]()
        var index = 1
        while index < tokens.count {
            let token = tokens[index]
            if token.hasPrefix("--") {
                if !token.contains("=") {
                    index += 1
                }
                if index >= tokens.count {
                    break
                }
                handleLongCommands(tokens, index, token, &options)
            } else if token.hasPrefix("-") {
                index += 1
                if index >= tokens.count {
                    break
                }
                handleShortCommands(tokens, index, token, &options)
            } else {
                options.append(.url(token))
            }
            index += 1
        }
        return options
    }
}

struct CurlParseResult {
    var url: URL?
    var user: String?
    var password: String?
    var postData: String?
    var headers: [String: String]
    var postFields: [String: String]
    var files: [String: String]
    var httpMethod: String
}

public struct CurlParser {
    public private(set) var command: String

    init(command: String) {
        self.command = command
    }

    static func compile(_ options: [CurlOption]) -> CurlParseResult {
        var url = ""
        var user: String?
        var password: String?
        var postData: String?
        var headers: [String: String] = [:]
        var postFields: [String: String] = [:]
        var files: [String: String] = [:]
        var httpMethod: String?

        for option in options {
            switch option {
            case .url(let str):
                url = str
            case .data(let data):
                postData = data
            case .form(let key, let value):
                if value.hasPrefix("@") {
                    files[key] = value
                } else {
                    postFields[key] = value
                }
            case .header(let key, let value):
                headers[key] = value
            case .referer(let str):
                headers["Referer"] = str
            case .userAgent(let str):
                headers["User-Agent"] = str
            case .user(let aUser, let aPassword):
                user = aUser
                password = aPassword
            case .requestMethod(let method):
                httpMethod = method
            }
        }

        let finalHTTPMethod: String = {
            if let httpMethod = httpMethod {
                return httpMethod
            }
            if postData != nil {
                return "POST"
            }
            if !postFields.isEmpty {
                return "POST"
            }
            if !files.isEmpty {
                return "POST"
            }
            return "GET"
        }()

        url = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        do {
            let pattern = "https?://(.*)@(.*)"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, url.count))
            if matches.count > 0 {
                let usernameRange = matches[0].range(at: 1)
                let start = url.index(url.startIndex, offsetBy: usernameRange.location)
                let end = url.index(url.startIndex, offsetBy: usernameRange.location + usernameRange.length)
                let substring = url[start ..< end]
                let components = substring.components(separatedBy: ":")
                if user == nil {
                    user = components[0]
                    if components.count >= 2 {
                        password = components[1]
                    }
                }
                url.removeSubrange(start ... end)
            }
        } catch {}

        return CurlParseResult(url: URL(string: url), user: user, password: password, postData: postData, headers: headers, postFields: postFields, files: files, httpMethod: finalHTTPMethod)
    }

    func parse() -> CurlParseResult {
        let command = self.command.trimmingCharacters(in: CharacterSet.whitespaces)
        let slices = Lexer.tokenize(command)
        let options = Lexer.convertTokensToOptions(slices)
        let result = CurlParser.compile(options)
        return result
    }
}
