//
//  DataText.swift
//  Image To Text
//
//  Created by Sorfian on 13/05/23.
//

import Foundation
import CoreData

enum Section {
    case all
}

public class DataTextResult: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataTextResult> {
        return NSFetchRequest<DataTextResult>(entityName: "DataTextResult")
    }
    
    @NSManaged public var input: String
    @NSManaged public var result: Int
    @NSManaged public var dateTime: Date
}

//struct DataText: Hashable {
//    var input: String = ""
//    var result: String = ""
//
//    init(input: String, result: String) {
//        self.input = input
//        self.result = result
//    }
//}
