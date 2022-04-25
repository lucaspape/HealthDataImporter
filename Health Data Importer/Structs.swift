//
//  Structs.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import HealthKit

struct HeartRateDataStructure {
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

struct ConfigureInput {
    let label: String
    let placeholder: String
}
