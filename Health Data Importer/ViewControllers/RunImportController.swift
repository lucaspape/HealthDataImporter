//
//  RunImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class RunImportController:UIViewController {
    var dataStructure: DataStructure?
    var urls: [URL]?
    var datatype: Datatype?
    
    private var typesToShare: Set<HKSampleType>{
        return [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
    }
    
    private var healthStore: HKHealthStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Importing"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestHealthAccess { success, error in
            if(success){
                DispatchQueue.global(qos: .background).async {
                    self.importFiles(urls: self.urls!)
                }
            }else{
                Util.showAlert(controller: self, title: "Error accessing health data", message: "There was an error accessing the health data") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
                
                print(error)
            }
        }
    }
    
    func showLoading(message: String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()

            alert.view.addSubview(loadingIndicator)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func hideLoading(completion: @escaping () -> Void){
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    func requestHealthAccess(completion: @escaping (Bool, String) -> Void){
        showLoading(message: "Accessing health data...")
        
        if(HKHealthStore.isHealthDataAvailable()){
            healthStore = HKHealthStore()
            
            healthStore.requestAuthorization(toShare: typesToShare, read: nil) { success, error in
                self.hideLoading {
                    if(success){
                        completion(true, "")
                    }else if(error != nil){
                        completion(true, error!.localizedDescription)
                    }else{
                        completion(false, "Access to health data failed")
                    }
                }
            }
        }else{
            hideLoading {
                completion(false, "Access to health data failed")
            }
        }
    }
    
    func importFiles(urls: [URL]){
        showLoading(message: "Importing files...")
        
        switch datatype!.identifier {
            case .heartRate:
                for url in urls {
                    importHeartRateFile(url: url, heartRateDataStructure: dataStructure  as! HeartRateDataStructure) { success, inserted, errors in
                        self.hideLoading {
                            DispatchQueue.main.async {
                                if(success){
                                    Util.showAlert(controller: self,title: "Imported data successfully", message: "Successfully inserted " + String(inserted) + " objects") {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }else{
                                    Util.showAlert(controller: self,title: "Failed to import data", message: "There was an error importing the data") {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            }
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
                    
                    let heartRateString = String(values[heartRateDataStructure.dataPosition])
                    
                    let heartRate = Double(heartRateString)!
                    
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
