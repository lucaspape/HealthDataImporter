//
//  Util.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class Util {
    static let datatypes = [Datatype(name: "Heart-Rate", identifier: .heartRate)]
    
    static var typesToShare: Set<HKSampleType> {
        get {
            var types: Set<HKSampleType> = []
            
            for type in datatypes {
                types.insert(HKQuantityType.quantityType(forIdentifier: type.identifier)!)
            }
            
            return types
        }
    }
    
    static let importSources = [ImportSource(name: "Files", identifier: "files"), ImportSource(name: "URL", identifier: "url")]
    static let configurationInputs:[HKQuantityTypeIdentifier: [ConfigureInput]] = [HKQuantityTypeIdentifier.heartRate: [
        ColumnPickerInput(identifier: .dataPosition, label: "Data position", subInputs: [], multiSelect: false),
        ColumnPickerInput(identifier: .datePositions, label: "Date positions", subInputs: [TextConfigureInput(identifier: .dateFormat, label: "Date format", placeholder: "dd.MM.yy" + Util.dateSeperator + "HH.mm", keyboardType: .default)], multiSelect: true)]]
    
    static let dateSeperator = ":"
    
    static func inputListToDataStructure(input: [InputIdentifier: Any], datatype: Datatype) throws -> DataStructure {
        let dataStructure: DataStructure
        
        switch datatype.identifier {
            case .heartRate:
                let dataPosition = input[.dataPosition] as! [Int]
                let datePositions = input[.datePositions] as! [Int]
                let dateFormat = input[.dateFormat] as! String
                let dateSeperator = Util.dateSeperator
            
                dataStructure = HeartRateDataStructure(dateFormat: dateFormat, datePositions: datePositions, dateSeperator: dateSeperator, dataPosition: dataPosition[0], skipFirstLine: true)
            default:
                throw "Unsupported identifier " + datatype.name
        }
        
        return dataStructure
    }
    
    static func showAlert(controller: UIViewController, title: String, message: String, onOkButton: @escaping () -> Void){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            onOkButton()
        }))
        controller.present(alert, animated: true, completion: nil)
    }
    
    static func downloadFile(urlString: String, completion: @escaping (Bool, URL?, Error?) -> Void){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy"
        
        let currentDate = dateFormatter.string(from: Date())
        let yesterdayDate = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!)!)
        
        let url = URL(string: urlString.replacingOccurrences(of: "{CURRENT_DATE}", with: currentDate).replacingOccurrences(of: "{LAST_DATE}", with: yesterdayDate))
        
        if(url != nil){
            let task = URLSession.shared.downloadTask(with: url!) { localURL, urlResponse, error in
                let response = urlResponse as! HTTPURLResponse
                
                if(response.statusCode == 200 && localURL != nil){
                    do {
                        let destinationUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(url!.lastPathComponent)
                        
                        if(FileManager.default.fileExists(atPath: destinationUrl.path)){
                            try FileManager.default.removeItem(at: destinationUrl)
                        }
                        
                        try FileManager.default.copyItem(at: localURL!, to: destinationUrl)
                        completion(true, destinationUrl, nil)
                    }catch{
                        completion(false, nil, nil)
                    }
                }else{
                    completion(false, nil, error)
                }
            }
            
            task.resume()
        }else{
            completion(false, nil, "Error parsing URL")
        }
    }
    
    static func showLoading(controller: UIViewController, message: String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()

            alert.view.addSubview(loadingIndicator)
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    static func hideLoading(controller: UIViewController,completion: @escaping () -> Void){
        DispatchQueue.main.async {
            controller.dismiss(animated: false, completion: completion)
        }
    }
    
    static var backgroundScheduler:BackgroundScheduler?
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
