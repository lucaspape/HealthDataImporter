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
    static let importSources = [ImportSource(name: "Files", identifier: "files")]
    static let configurationInputs = [HKQuantityTypeIdentifier.heartRate:
                                        [ConfigureInput(label: "Data position", placeholder: "2", keyboardType: .numberPad), ConfigureInput(label: "Date positions (comma or dot separated)", placeholder: "0,1", keyboardType: .decimalPad), ConfigureInput(label: "Date format", placeholder: "dd-MM-yy_HH-mm", keyboardType: .default), ConfigureInput(label: "Date seperator", placeholder: "_", keyboardType: .default)]]
    
    static func inputListToDataStructure(input: [String], datatype: Datatype) throws -> DataStructure {
        let dataStructure: DataStructure
        
        switch datatype.identifier {
            case .heartRate:
                let dataPosition = Int(String(input[0]))
                
                if(dataPosition == nil){
                    throw "Error converting string to integer"
                }
            
                var datePositions: [Int] = []
            
                var datePositionsString = input[1].split(separator: ",")
            
                if(input[1].contains(".")){
                    datePositionsString = input[1].split(separator: ".")
                }
            
                for position in datePositionsString{
                    let positionInt = Int(String(position))
                    
                    if(positionInt != nil){
                        datePositions.append(positionInt!)
                    }else{
                        throw "Error converting string to integer"
                    }
                }
            
                let dateFormat = input[2]
                let dateSeperator = input[3]
            
            
                dataStructure = HeartRateDataStructure(dateFormat: dateFormat, datePositions: datePositions, dateSeperator: dateSeperator, dataPosition: dataPosition!, skipFirstLine: true)
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
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
