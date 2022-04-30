//
//  Structs.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import HealthKit
import UIKit

protocol DataStructure: Codable {
    
}

struct HeartRateDataStructure: DataStructure {
    let dateFormat: String
    let datePositions: [Int]
    let dateSeperator: String
    let dataPosition: Int
    let skipFirstLine: Bool
}

struct Datatype {
    let name: String
    let identifier: HKQuantityTypeIdentifier
}

struct ImportSource {
    let name: String
    let identifier: String
}

enum InputIdentifier {
    case dataPosition, datePositions, dateFormat
}

protocol ConfigureInput {
    var label: String { get }
    var identifier: InputIdentifier { get }
}

struct TextConfigureInput: ConfigureInput {
    let identifier: InputIdentifier
    let label: String
    let placeholder: String
    let keyboardType: UIKeyboardType
}

struct ColumnPickerInput: ConfigureInput {
    let identifier: InputIdentifier
    let label: String
    let subInputs: [ConfigureInput]
    let multiSelect: Bool
}

protocol Sync: Codable {
    
}

struct HeartRateSync: Sync {
    let urlString: String
    let dataStructure: HeartRateDataStructure
}

struct SyncWithId {
    let sync: Sync
    let id: String
}

struct Log {
    let id: String
    let date: Date
    let successCount: Int
    let errorCount: Int
    let type: String
    let fileName: String
}
