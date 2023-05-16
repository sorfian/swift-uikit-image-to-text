//
//  DateExtension.swift
//  Image To Text
//
//  Created by Sorfian on 16/05/23.
//

import Foundation

extension Date {
    func stringToDate(stringDate: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +SSSS"
        let stringToDate = dateFormatter.date(from: stringDate)!
        return stringToDate
    }
    
    func dateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMM yyyy, HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "ID")
        let dateToString = dateFormatter.string(from: date)
        return dateToString
    }
}
