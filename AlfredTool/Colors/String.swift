//
//  String.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation

extension String {
    
    func stringByPreservingCharacters(_ preservedCharacters:String) -> String {
        let set = CharacterSet(charactersIn: preservedCharacters).inverted
        var stringArray = self.components(separatedBy: set)
        if stringArray.count != 1 {
            stringArray = stringArray.filter({ !$0.isEmpty })
        }
        return stringArray.joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func componentsSeparateByCharacters(_ preservedCharacters:String) -> [String] {
        let set = CharacterSet(charactersIn: preservedCharacters)
        let stringArray = self.components(separatedBy: set)
        guard stringArray.count != 1 else { return stringArray }
        return stringArray.filter({ !$0.isEmpty })
    }
}
