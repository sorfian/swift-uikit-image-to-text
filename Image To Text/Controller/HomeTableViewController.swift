//
//  HomeTableViewController.swift
//  Image To Text
//
//  Created by Sorfian on 12/05/23.
//

import UIKit
import Vision
import VisionKit
import CoreData
import PhotosUI

class HomeTableViewController: UITableViewController {
    
    var fetchResultController: NSFetchedResultsController<DataTextResult>!
    
    lazy var dataSource = configureDataSource()
    
    let button = UIButton()
    
    var databaseStorage: Bool = false
    
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    let dateFormatter = DateFormatter()
    
    var fileURL: URL?
    
    let dataStorage: DataStorage = DataStorage()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = documentsUrl?.appending(path: "filedatatext.txt")
        
        fetchDataTextFromFile()
        tableView.dataSource = dataSource
        
        button.backgroundColor = .systemBlue
        button.setTitle("Add Input", for: .normal)
        button.layer.cornerRadius = 5
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        button.addTarget(self, action: #selector(scanDocument), for: .touchUpInside)
        
        configureOCR()
        print(databaseStorage)

    }
    
    @objc private func scanDocument() {
//        let scanVC = VNDocumentCameraViewController()
//        scanVC.delegate = self
//        present(scanVC, animated: true)
        
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 3
        config.filter = PHPickerFilter.any(of: [.images, .livePhotos, .panoramas, .screenshots])
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        button.isEnabled = false
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([self.ocrRequest])
        } catch {
            print(error)
        }
    }
    
    private func configureOCR() {
        
        ocrRequest = VNRecognizeTextRequest { [self] (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let topCandidate = observations[0].topCandidates(1).first!
            let ocrText = topCandidate.string
            
            print("HASIL ==> \(ocrText)")
            
            var expressionList: [String] = []
            let numList = ocrText.components(separatedBy: ["\u{00D7}", "x", "X", ":", "+", "-"])
            
            let _ = ocrText.map { char in
                
                if (char != " ") {
                    if char.description == "\u{00D7}" {
                        expressionList.append("*")
                    } else if char.description == ":" {
                        expressionList.append("/")
                    } else if char.description == "+" {
                        expressionList.append("+")
                    } else if char.description == "-" {
                        expressionList.append("-")
                    }
                }
                
            }
            print(numList)
            print(expressionList)
            
            let firstArgument = numList[0]
            let secondArgument = numList[1]
            let expression = expressionList[0]
            
            let finalText = firstArgument + expression + secondArgument
            
            print(finalText)
            var finalResult = 0
            
            let expressionResult = NSExpression(format: finalText)
            if let result = expressionResult.expressionValue(with: nil, context: nil) as? Int {
                print(result)
                finalResult = result
            }
            
            
            if databaseStorage {
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                    let dataTextResult = DataTextResult(context: appDelegate.persistentContainer.viewContext)

                    dataTextResult.input = finalText
                    dataTextResult.result = finalResult
                    dataTextResult.dateTime = Date()

                    print("Saving data to context...")
                    appDelegate.saveContext()
                }
                
                DispatchQueue.main.async {
                    self.button.isEnabled = true
                    self.fetchDataTextFromDB()
                }
                
            } else {
    //            Save to encrypted file
                let saveToFile = "\(finalText);\(finalResult);\(Date())\n"
                
                EncryptedArchive.file(decrypt: true)
                
                print(fileURL!)
                
                if let filePath = fileURL {
                   
                    do {
                        if var stringFromFile = try? String(contentsOf: filePath, encoding: .utf8) {
                            stringFromFile.write(saveToFile)
                            try stringFromFile.write(to: filePath, atomically: true, encoding: .utf8)
                            
                        } else {
                           try saveToFile.write(to: filePath, atomically: true, encoding: .utf8)
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    EncryptedArchive.file(encrypt: true)
                    try? FileManager.default.removeItem(at: filePath)
                    
                }
                DispatchQueue.main.async {
                    self.button.isEnabled = true
                    self.fetchDataTextFromFile()
                }
            }
        }
        
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["en-US", "en-GB"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    
    private func configureDataSource() -> UITableViewDiffableDataSource<Section, DataTextResult> {
        let cellIdentifier = "resultCell"

        let dataSource = UITableViewDiffableDataSource<Section, DataTextResult>(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, textData in
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! HomeTableViewCell
                let dateTime = self.dateFormatter.string(from: Date())
                cell.inputValueLabel.text = textData.input
                cell.resultValueLabel.text = String(textData.result)
                cell.dateTimeLabel.text = String(describing: textData.dateTime)
                print("HASIL ==> \(dateTime)")

                return cell
            }
        )

        return dataSource
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func saveToButton(sender: UIStoryboard) {
        let storageSourceRequestController = UIAlertController(title: "", message: "Choose your storage source", preferredStyle: .actionSheet)
        
        let fileStorageAction = UIAlertAction(title: "Encrypted File", style: .default) { action in
            self.databaseStorage = false
            let snapshotFile = self.dataStorage.fetchDataTextFromEncryptedFile(url: self.fileURL)
            
            if let snapshotFile = snapshotFile {
                self.dataSource.apply(snapshotFile, animatingDifferences: false)
            }
        }
        
        let databaseStorageAction = UIAlertAction(title: "Database Storage", style: .default) { action in
            self.databaseStorage = true
            let snapshotDB = self.dataStorage.fetchDataTextFromDBStorage(delegate: HomeTableViewController())
            
            if let snapshotDB = snapshotDB {
                self.dataSource.apply(snapshotDB, animatingDifferences: false)
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
        
        storageSourceRequestController.addAction(fileStorageAction)
        storageSourceRequestController.addAction(databaseStorageAction)
        storageSourceRequestController.addAction(cancelAction)
        
//            For Ipad
        if let popoverPresentationController = storageSourceRequestController.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = view.bounds
        }
        
        present(storageSourceRequestController, animated: true, completion: nil)
        print(databaseStorage)
    }
}

extension HomeTableViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        processImage(scan.imageOfPage(at: 0))
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}


extension HomeTableViewController: NSFetchedResultsControllerDelegate {
    
    func fetchDataTextFromFile() {
        let snapshotFile = DataStorage().fetchDataTextFromEncryptedFile(url: fileURL)
        
        if let snapshotFile = snapshotFile {
            dataSource.apply(snapshotFile, animatingDifferences: false)
        }
    }
    
    func fetchDataTextFromDB() {
        let snapshotDB = DataStorage().fetchDataTextFromDBStorage(delegate: HomeTableViewController())
        
        if let snapshotDB = snapshotDB {
            dataSource.apply(snapshotDB, animatingDifferences: false)
        }
    }
}

extension HomeTableViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        results.forEach { result in
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                    DispatchQueue.main.async {
                        guard let image = reading as? UIImage, error == nil
                        else {
                            return
                        }
                        
                        self.processImage(image)
                        picker.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
}
