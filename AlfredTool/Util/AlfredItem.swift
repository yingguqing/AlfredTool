import Foundation

/// Alfred's script filter response [JSON spec][1]
/// [1]: https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
struct AlfredItem: Codable {
    /// When this item is actioned, this is what will be passed
    /// through to the connected output action.
    ///
    /// Although optional according to the spec,
    /// we require arg because the spec strongly recommends so.
    /// 传递给后续流程的参数，即 {query}
    var arg: String = ""

    /// This is a unique identifier for the item.
    /// It helps Alfred learn about this item for
    /// subsequent sorting and ordering of the user's actioned results.
    ///
    /// It is important that you use the same UID throughout subsequent
    /// executions of your script to take advantage of Alfred's knowledge
    /// and sorting. If you would like Alfred to always show the results
    /// in the order you return them from your script, exclude the UID field.
    /// 给 Alfred 进行记忆和排序的编号(有值才能记忆，如果固定排序，就不要设置)
    var uid: String?

    /// 标题内容
    var title: String = ""
    var subtitle: String?

    /// - `true`: Alfred will action this item when the user presses return.
    /// - `false`: Alfred will do nothing.
    /// - `nil`: Treated same as `true`.
    /// 条目是否能够被选择
    var valid: Bool?

    /// The `match` field enables you to define what Alfred matches against
    /// when the workflow is set to "Alfred Filters Results".
    /// If `match` is present, it fully replaces matching
    /// on the `title` property.
    /// Note that the match field is always treated as case insensitive,
    /// and intelligently treated as diacritic insensitive.
    /// If the search query contains a diacritic,
    /// the match becomes diacritic sensitive.
    /// This option pairs well with the "Alfred Filters Results".
    var match: String?

    /// This is populated into Alfred's search field
    /// if the user auto-completes the selected result (⇥ by default).
    var autocomplete: String?

    /// A Quick Look URL which will be visible if the user uses
    /// the Quick Look feature within Alfred (tapping shift, or cmd+y).
    /// Both file paths and web URLs are acceptable.
    /// 当使用 Alfred 提供的快速浏览功能时，跳转的链接，例如按下 Cmd+Y
    var quicklookurl: URL?

    /// - nil: Alfred treats `arg` as just a string.
    /// - .file: Alfred treats `arg` as a file on the system.
    /// if the `arg` is not a valid path, Alfred won't show the item.
    /// This has a small performance penalty.
    /// - .fileSkipCheck: same as `.file`, but Alfred won't validate path.
    /// the item will be shown irrespective of `arg` being valid path.
    var type: Typ?

    /// These allow the user to perform actions on the item
    /// like a file just like they can with Alfred's built-in file filters.
    enum Typ: String, Codable {
        case file
        case fileSkipCheck = "file:skipcheck"
    }

    /// Defines the text the user will get when
    /// copying the selected item with ⌘C or
    /// displaying large type with ⌘L.
    var text: Text?

    /// If these are not defined,
    /// you will inherit Alfred's standard behaviour where
    /// the `arg` is copied to the Clipboard or used for Large Type.
    struct Text: Codable {
        var copy: String?
        var largetype: String?
        init(
            copy: String? = nil,
            largetype: String? = nil
        ) {
            self.copy = copy
            self.largetype = largetype
        }
    }

    /// The icon displayed in the result row.
    var icon: Icon?

    /// [Detailed documentation][1]
    /// [1]: https://pkg.go.dev/github.com/deanishe/awgo@v0.28.0#Icon
    /// icontype 为 None 时，icon 指向一个具体的图标文件
    /// icontype 为 ‘filetype’ 时，icon 则应该指向某个文件，这时将会使用这个文件的内打包的 icon 文件，例如 ‘/Applications/Safari.app’
    /// icontype 为 ‘filetype’ 时，icon 应该是某个文件类型，例如 ‘pdf’, ‘public.folder’
    class Icon: Codable {
        private let type: String?
        private let path: String

        private init(type: String? = nil, path: String) {
            self.type = type
            self.path = path
        }

        /// Use image at `filePath` as an icon.
        static func fromImage(at filePath: URL) -> Icon {
            Icon(path: filePath.path)
        }

        /// Use the standard icon for the given [UTI][1].
        /// [1]: https://en.wikipedia.org/wiki/Uniform_Type_Identifier
        static func forFileType(uti: String) -> Icon {
            Icon(type: "filetype", path: uti)
        }

        /// Use the icon of the file at `filePath`.
        static func ofFile(at filePath: URL) -> Icon {
            Icon(type: "fileicon", path: filePath.path)
        }
        
/*
        static func forTitle(_ title:String) -> Icon {
            Icon(path: itemIcon(title: title))
        }
*/
    }

    /// The mod element gives you control over how the modifier keys react.
    /// You can now define the valid attribute to mark if the result is valid
    /// based on the modifier selection and set a different arg to be passed out
    /// if actioned with the modifier.
    var mods: Mods?

    struct Mods: Codable {
        var alt: Mod?
        var cmd: Mod?
        var control: Mod?
        var shift: Mod?
        static func mods(
            alt: Mod? = nil,
            cmd: Mod? = nil,
            control: Mod? = nil,
            shift: Mod? = nil
        ) -> Mods {
            var m = Mods()
            m.alt = alt
            m.cmd = cmd
            m.control = control
            m.shift = shift
            return m
        }
    }

    /// When the item is actioned while the modifier key is pressed,
    /// these values override the original item's values.
    struct Mod: Codable {
        var arg: String?
        var subtitle: String?
        var valid: Bool?
        var icon: Icon?
        static func mod(
            arg: String? = nil,
            subtitle: String? = nil,
            valid: Bool? = nil,
            icon: Icon? = nil
        ) -> Mod {
            var m = Mod()
            m.arg = arg
            m.subtitle = subtitle
            m.valid = valid
            m.icon = icon
            return m
        }
    }

    static func item(
        arg: String = "",
        title: String = "",
        uid: String? = nil,
        subtitle: String? = nil,
        valid: Bool? = nil,
        match: String? = nil,
        autocomplete: String? = nil,
        quicklookurl: URL? = nil,
        type: Typ? = nil,
        text: Text? = nil,
        icon: Icon? = nil,
        mods: Mods? = nil
    ) -> AlfredItem {
        var i = AlfredItem()
        i.arg = arg
        i.title = title
        i.uid = uid
        i.subtitle = subtitle
        i.valid = valid
        i.match = match
        i.autocomplete = autocomplete
        i.quicklookurl = quicklookurl
        i.type = type
        i.text = text
        i.icon = icon
        i.mods = mods
        return i
    }
    
    func toJsonString(sortKeys: Bool = true) -> String {
        return [self].toJsonString(sortKeys: sortKeys)
    }
}

extension Array where Element == AlfredItem {
    func toJsonString(sortKeys: Bool = false) -> String {
        let encoder = JSONEncoder()

        encoder.outputFormatting.update(with: .prettyPrinted)
        if sortKeys {
            encoder.outputFormatting.update(with: .sortedKeys)
        }
        if #available(macOS 10.15, *) {
            encoder.outputFormatting.update(with: .withoutEscapingSlashes)
        }

        let jsonData = try! encoder.encode(["items": self])
        return String(data: jsonData, encoding: .utf8)!
    }
    
}

