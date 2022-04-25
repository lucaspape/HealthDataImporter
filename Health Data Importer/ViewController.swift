//
//  ViewController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import HealthKit

struct HeartRateDataStructure {
    let dateFormat: String
    let datePositions: [Int]
    let dateSeperator: String
    let dataPosition: Int
    let skipFirstLine: Bool
}

class ViewController: UIViewController, UIDocumentPickerDelegate {
    
    private var selectFileButton: UIButton!
    
    private var healthStore: HKHealthStore!
    
    private let selectedSampleType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    private var typesToShare: Set<HKSampleType>{
        return [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectFileButton = UIButton()
        self.selectFileButton.translatesAutoresizingMaskIntoConstraints = false
        self.selectFileButton.setTitle("Select files to import", for: .normal)
        self.selectFileButton.setTitleColor(UIColor.label, for: .normal)
        self.selectFileButton.addTarget(self, action: #selector(self.selectFileButtonPressed), for: .touchUpInside)
        
        self.view.addSubview(self.selectFileButton)
        
        self.setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestHealthAccess()
    }
    
    func requestHealthAccess(){
        if(HKHealthStore.isHealthDataAvailable()){
            healthStore = HKHealthStore()
            
            healthStore.requestAuthorization(toShare: typesToShare, read: nil) { success, error in
                if(success){
                    print("success")
                }else if(error != nil){
                    print(error!)
                }else{
                    print("No access to heart data")
                }
            }
        }else{
            print("No access to health data!")
        }
    }
    
    func setupConstraints(){
        selectFileButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        selectFileButton.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        selectFileButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        selectFileButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.setNeedsLayout()
    }
    
    @objc func selectFileButtonPressed(){
        showFilePicker()
    }
    
    func showFilePicker(){
        let supportedTypes = UTType.types(tag: "csv",
                                     tagClass: UTTagClass.filenameExtension,
                                     conformingTo: nil)
        
        let pickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        pickerViewController.delegate = self
        pickerViewController.allowsMultipleSelection = false
        pickerViewController.shouldShowFileExtensions = true
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        importFiles(urls: urls)
    }
    
    func importFiles(urls: [URL]){
        switch selectedSampleType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate)!:
                for url in urls {
                    importHeartRateFile(url: url, heartRateDataStructure: HeartRateDataStructure(dateFormat: "dd-MM-yy_HH-mm", datePositions: [0,1], dateSeperator: "_", dataPosition: 2, skipFirstLine: true)) { success, inserted, errors in
                        if(success){
                            print("Successfully inserted " + String(inserted) + " objects")
                        }else{
                            print(errors)
                        }
                    }
                }
            default:
                print("unknown type")
        }
    }
    
    func importHeartRateFile(url: URL, heartRateDataStructure: HeartRateDataStructure, completion: @escaping (Bool, Int, [String]) -> Void){
        print("Importing: " + url.path)
        
        do {
            let data = try String(contentsOfFile: url.path)
            
            let lines = data.split(separator: "\n")
            
            var firstLine = true
            
            let group = DispatchGroup()
            
            var errors:[String] = []
            var inserted = 0
            
            for line in lines{
                let values = line.split(separator: ",")
                
                if(firstLine && heartRateDataStructure.skipFirstLine){
                    firstLine = false
                }else{
                    var dateString = ""
                    
                    for datePosition in heartRateDataStructure.datePositions {
                        dateString += values[datePosition] + heartRateDataStructure.dateSeperator
                    }
                    
                    dateString = String(dateString.dropLast())
                    
                    let heartRate = Double(String(values[heartRateDataStructure.dataPosition]))!
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = heartRateDataStructure.dateFormat
                    let date = dateFormatter.date(from: dateString)!
                    
                    group.enter()
                    
                    saveHeartRate(date: date, heartRate: heartRate) { success, error in
                        if(success){
                            inserted+=1
                        }else if(error != nil){
                            errors.append(error!.localizedDescription)
                        }else{
                            errors.append("Unknown error while inserting data")
                        }
                        
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(errors.count == 0, inserted, errors)
            }
        } catch {
            completion(false, 0, ["Error reading file"])
        }
    }
    
    func saveHeartRate(date: Date, heartRate: Double, completion: @escaping (Bool, Error?) -> Void){
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let quantity = HKQuantity(unit: unit, doubleValue: heartRate)
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let heartRateSample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        self.healthStore.save(heartRateSample, withCompletion: completion)
    }
}

