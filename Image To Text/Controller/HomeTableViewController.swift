//
//  HomeTableViewController.swift
//  Image To Text
//
//  Created by Sorfian on 12/05/23.
//

import UIKit
import Vision
import VisionKit

class HomeTableViewController: UITableViewController {
    
    enum Section {
        case all
    }
    
    var textResult: [DataText] = [
        DataText(input: "1+2", result: "3"),
        DataText(input: "2+2", result: "4"),
        DataText(input: "3+3", result: "6"),
        DataText(input: "3+4", result: "7"),
        DataText(input: "3+2", result: "5"),
        DataText(input: "3+6", result: "9"),
        DataText(input: "3+5", result: "8"),
        DataText(input: "3+7", result: "10"),
    ]
    
    lazy var dataSource = configureDataSource()
    
    let button = UIButton()
    
    var databaseStorage: Bool = false
    
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        updateSnapshot()
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
        let scanVC = VNDocumentCameraViewController()
        scanVC.delegate = self
        present(scanVC, animated: true)
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
        ocrRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var ocrText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                ocrText += topCandidate.string + "\n"
            }
            
            
            DispatchQueue.main.async {
                self.button.isEnabled = true
            }
        }
        
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["en-US", "en-GB"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    
    private func configureDataSource() -> UITableViewDiffableDataSource<Section, DataText> {
        let cellIdentifier = "resultCell"

        let dataSource = UITableViewDiffableDataSource<Section, DataText>(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, textData in
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! HomeTableViewCell

                cell.inputValueLabel.text = textData.input
                cell.resultValueLabel.text = textData.result

                return cell
            }
        )

        return dataSource
    }
    
    private func updateSnapshot(animatingChange: Bool = false) {

        // Create a snapshot and populate the data
        var snapshot = NSDiffableDataSourceSnapshot<Section, DataText>()
        snapshot.appendSections([.all])
        snapshot.appendItems(textResult, toSection: .all)

        dataSource.apply(snapshot, animatingDifferences: animatingChange)
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
