//
//  DataStorage.swift
//  Image To Text
//
//  Created by Sorfian on 15/05/23.
//

import UIKit
import CoreData

class DataStorage {
    private var fetchResultController: NSFetchedResultsController<DataTextResult>?
    private var dataText: [DataTextResult] = []
    private var dataTextResult: DataTextResult!
    private var snapshot: NSDiffableDataSourceSnapshot<Section, DataTextResult>?
    
    func fetchDataTextFromDBStorage(delegate delegateClass: NSFetchedResultsControllerDelegate) -> NSDiffableDataSourceSnapshot<Section, DataTextResult>? {
        
        let fetchRequest: NSFetchRequest<DataTextResult> = DataTextResult.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController?.delegate = delegateClass
            
            do {
                try fetchResultController?.performFetch()
                
                dataText.removeAll()
                 snapshot = updateSnapshot(fromDB: true)
            } catch {
                print(error)
            }
        }
        return snapshot
    }
    
    func fetchDataTextFromEncryptedFile(url fileURL: URL?) -> NSDiffableDataSourceSnapshot<Section, DataTextResult>? {
        
        EncryptedArchive.file(decrypt: true)
        
        let delimiter = ";"
        var items:[(input:String, result:Int, dateTime: String)]
        
        if let filePath = fileURL {
            do {
                let content = try String(contentsOf: filePath, encoding: .utf8)
                items = []
                
                let lines: [String] = content.components(separatedBy: .newlines)
                print(lines)
                for line in lines {
                    var values: [String] = []
                    if line != "" {
                        values = line.components(separatedBy: delimiter)
                        let item = (input: values[0], result: Int(values[1])!, dateTime: values[2])
                        items.append(item)
                    }
                }
                
                dataText.removeAll()
                
                for item in items {
                    let date = Date()
                    let stringToDate = date.stringToDate(stringDate: item.dateTime)
                    
                    if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                        dataTextResult = DataTextResult(context: appDelegate.persistentContainer.viewContext)
        
                        dataTextResult.input = item.input
                        dataTextResult.result = item.result
                        dataTextResult.dateTime = stringToDate
                       
                        dataText.append(dataTextResult)
                        
                        appDelegate.persistentContainer.viewContext.delete(dataTextResult)
                    }
                }
                
                snapshot = updateSnapshot()
                
            } catch {
                print(error.localizedDescription)
            }
            print(filePath)
            try? FileManager.default.removeItem(at: filePath)
        }
        
        return snapshot
    }
    
    func updateSnapshot(animatingChange: Bool = false, fromDB fromDatabase: Bool = false) -> NSDiffableDataSourceSnapshot<Section, DataTextResult> {
        
        if fromDatabase {
            if let fetchedObjects = fetchResultController?.fetchedObjects {
                dataText = fetchedObjects
            }
        }

        // Create a snapshot and populate the data
        var snapshot = NSDiffableDataSourceSnapshot<Section, DataTextResult>()
        snapshot.appendSections([.all])
        snapshot.appendItems(dataText, toSection: .all)
        
        return snapshot

        
    }
}
