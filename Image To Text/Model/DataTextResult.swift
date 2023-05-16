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

