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
        
        button.backgroundColor = Config.theme()
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

    }
    
    @objc private func scanDocument() {
        
//        Take a picture from camera if your Config camera is set to true
//        Get the picture from camera roll if your Config camera is set to false
        
        if Config.camera {
            let scanVC = VNDocumentCameraViewController()
            scanVC.delegate = self
            present(scanVC, animated: true)
        } else {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = PHPickerFilter.any(of: [.images, .livePhotos, .panoramas, .screenshots])
            let vc = PHPickerViewController(configuration: config)
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
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
            
//            Store an arguments of number to array separated by arithmetic symbols
            let numList = ocrText.components(separatedBy: ["\u{00D7}", "x", "X", ":", "+", "-"])
            
//            Store an arithmetic expression to array
            var expressionList: [String] = []
            let _ = ocrText.map { char in
                
                if (char != " ") {
                    if char.description == "\u{00D7}" {
                        expressionList.append("*")
                    } else if char.description == "x" {
                        expressionList.append("*")
                    } else if char.description == "X" {
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
            
//            Show an alert when result is a text (not a number)
//            there is a single array of string when the result is a text
            if numList.count < 2 {
                self.button.isEnabled = true
                self.dismiss(animated: true, completion: nil)
                let alertController = UIAlertController(title: "Oops", message: "Text detection is not a number", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            
//            There is no data when arithmetic symbols not found
            if expressionList.isEmpty {
                self.button.isEnabled = true
                self.dismiss(animated: true, completion: nil)
                let alertController = UIAlertController(title: "Oops", message: "No arithmetic expression found!", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            
//            Assign the first and second argument, also arithmetic symbol to expression property
            let firstArgument = numList[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let secondArgument = numList[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let expression = expressionList[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
//            Show an alert when there is a arithmetic symbols found but the first and second arguments are not a number
//            Continue the logic when there is a number in first and second arguments.
            if (firstArgument.isNumber || secondArgument.isNumber) {
                
//                Convert the text result to arithmetic calculation and get the final result
                let finalText = firstArgument + expression + secondArgument
                var finalResult = 0
                
                let expressionResult = NSExpression(format: finalText)
                if let result = expressionResult.expressionValue(with: nil, context: nil) as? Int {
                    finalResult = result
                }
                
                //                Save the data to local database when database storage is set to true
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
//            Save the data to encrypted file when database storage is set to false
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
                
            } else {
                print("bukan number")
                self.button.isEnabled = true
                self.dismiss(animated: true, completion: nil)
                let alertController = UIAlertController(title: "Oops", message: "Text detection is not a number", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
                return
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
                let date = Date()
                cell.inputValueLabel.text = textData.input
                cell.resultValueLabel.text = String(textData.result)
                cell.dateTimeLabel.text = date.dateToString(date: textData.dateTime)

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
        
        storageSourceRequestController.view.tintColor = Config.theme()
        
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
            popoverPresentationController.sourceView = view.superview
            popoverPresentationController.sourceRect = view.bounds
        }
        
        present(storageSourceRequestController, animated: true, completion: nil)
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
        
        if results.isEmpty {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
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
