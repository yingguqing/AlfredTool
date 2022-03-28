//
//  Util.swift
//  Colors
//
//  Created by zhouziyuan on 2022/3/27.
//

import Foundation

extension Array {
    
    func value(index:Int) -> Element? {
        guard self.count > index else { return nil }
        return self[index]
    }
}
