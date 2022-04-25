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
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
