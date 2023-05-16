//
//  Constant.swift
//  Image To Text
//
//  Created by Sorfian on 16/05/23.
//

import UIKit

struct Config {
//    Set the color property to "red" to change the theme to red color
    static let color = "green"
    
//    Set the camera property to false to get picture from photo library or camera roll
    static let camera: Bool = false
    
    
    static let greenColor: UIColor = UIColor(named: "greenColor")!
    static let redColor: UIColor = UIColor(named: "redColor")!
    
    static func theme() -> UIColor {
        if color == "green" {
            return greenColor
        } else {
            return redColor
        }
    }
}
