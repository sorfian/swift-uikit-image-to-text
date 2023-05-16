//
//  StringExtension.swift
//  Image To Text
//
//  Created by Sorfian on 16/05/23.
//

import Foundation

extension String {
//    Regular expression to check whether the text detection is number or not
    var isNumber: Bool {
        return self.range(of: "^[0-9]*$", options: .regularExpression) != nil
    }
}
