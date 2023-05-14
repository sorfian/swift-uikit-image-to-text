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
    
    enum Section {
        case all
    }
    
    var dataText: [DataTextResult] = []
    var dataTextResult: DataTextResult!
    
    var fetchResultController: NSFetchedResultsController<DataTextResult>!
    
    lazy var dataSource = configureDataSource()
    
    let button = UIButton()
    
    var databaseStorage: Bool = false
    
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        fetchDataTextResult()
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
            
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                dataTextResult = DataTextResult(context: appDelegate.persistentContainer.viewContext)

                dataTextResult.input = ocrText
                dataTextResult.result = finalResult
                dataTextResult.dateTime = Date()

                print("Saving data to context...")
                appDelegate.saveContext()
            }
            
            
            DispatchQueue.main.async {
                self.button.isEnabled = true
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
        }
        
        let databaseStorageAction = UIAlertAction(title: "Database Storage", style: .default) { action in
            self.databaseStorage = true
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
    func fetchDataTextResult() {
//        Fetch data from data store
        let fetchRequest: NSFetchRequest<DataTextResult> = DataTextResult.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "dateTime", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
            
            do {
                try fetchResultController.performFetch()
                updateSnapshot()
            } catch {
                print(error)
            }
        }
    }
    
    func updateSnapshot(animatingChange: Bool = false) {
        if let fetchedObjects = fetchResultController.fetchedObjects {
            dataText = fetchedObjects
        }

        // Create a snapshot and populate the data
        var snapshot = NSDiffableDataSourceSnapshot<Section, DataTextResult>()
        snapshot.appendSections([.all])
        snapshot.appendItems(dataText, toSection: .all)

        dataSource.apply(snapshot, animatingDifferences: animatingChange)
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
                    }
                }
            }
            
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
