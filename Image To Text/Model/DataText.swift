//
//  DataText.swift
//  Image To Text
//
//  Created by Sorfian on 13/05/23.
//

import Foundation

struct DataText: Hashable {
    var input: String = ""
    var result: String = ""
    
    init(input: String, result: String) {
        self.input = input
        self.result = result
    }
}
