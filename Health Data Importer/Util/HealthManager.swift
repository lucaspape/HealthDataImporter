//
//  HealthManager.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 28.04.22.
//

import HealthKit
import BackgroundTasks

class HealthManager {
    var healthStore: HKHealthStore!
    
    private static let backgroundTaskId = "de.lucaspape.Health-Data-Importer.refresh"
    
    private let syncDatabase = SyncDatabase()
    private let syncLogDatabase = SyncLogDatabase()
    
    func requestHealthAccess(completion: @escaping (Bool, Error?) -> Void) {
        if(HKHealthStore.isHealthDataAvailable()){
            healthStore = HKHealthStore()
            
            healthStore.requestAuthorization(toShare: Util.typesToShare, read: Util.typesToShare) { success, error in
                if(success){
                    completion(true, nil)
                }else if(error != nil){
                    completion(false, error)
                }else{
                    completion(false, "Access to health data failed")
                }
            }
        }else{
            completion(false, "Access to health data failed")
        }
    }
    
    func importFiles(files: [URL], datatype: Datatype, dataStructure: DataStructure, importType: String, completion: @escaping (Bool, Int, [String]) -> Void) {
        switch datatype.identifier {
            case .heartRate:
                var errors:[String] = []
                var inserted = 0
            
                let group = DispatchGroup()
            
                for url in files {
                    group.enter()
                    
                    importHeartRateFile(url: url, heartRateDataStructure: dataStructure as! HeartRateDataStructure, importType: importType) { count, importErrors in
                        
                        inserted += count
                        
                        errors.append(contentsOf: importErrors)
                        
                        group.leave()
                    }
                }
            
                group.notify(queue: .main) {
                    completion(errors.count == 0, inserted, errors)
                }
            default:
                completion(false, 0, ["Unknown datatype " + datatype.name])
        }
    }
    
    func addSync(sync: Sync) throws {
        let success = syncDatabase.insert(sync: sync)
        
        if(!success){
            throw "Failed to save in DB"
        }
    }
    
    static func registerBackgroundTask(){
        BGTaskScheduler.shared.register(forTaskWithIdentifier: HealthManager.backgroundTaskId, using: nil) { task in
            runBackgroundTask(task: task)
        }
        
        print("Registered background task")
    }
    
    static private func runBackgroundTask(task: BGTask){
        print("Hello from background task")
        
        HealthManager.scheduleBackgroundTask()
        
        task.expirationHandler = {
            print("Task expired")
        }
        
        let healthManager = HealthManager()
        healthManager.requestHealthAccess { success, error in
            if(success){
                healthManager.runSync {
                    print("Sync done")
                    
                    task.setTaskCompleted(success: true)
                }
            }else{
                print("Cannot sync, no access to health data")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    static func scheduleBackgroundTask(){
        let request = BGAppRefreshTaskRequest(identifier: HealthManager.backgroundTaskId)
        
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
          try BGTaskScheduler.shared.submit(request)
            print("Scheduled background task")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func runSync(completion: @escaping () -> Void) {
        print("Running sync...")
        
        let syncs = syncDatabase.get()
        
        for sync in syncs {
            if(sync.sync is HeartRateSync){
                let sync = sync.sync as! HeartRateSync
                
                Util.downloadFile(urlString: sync.urlString) { success, url, error in
                    if(success){
                        self.importHeartRateFile(url: url!, heartRateDataStructure: sync.dataStructure, importType: "background-sync") { count, errors in
                            print("synced")
                        }
                    }else{
                        print("Failed to download data")
                        //TODO save error in log
                    }
                }
            }
        }
    }
    
    private func importHeartRateFile(url: URL, heartRateDataStructure: HeartRateDataStructure, importType: String, completion: @escaping (Int, [String]) -> Void){
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
                if(self.syncLogDatabase.insert(log: Log(id: UUID().uuidString, date: Date.now, successCount: inserted, errorCount: errors.count, type: importType, fileName: url.lastPathComponent))){
                    print("Saved log")
                }else{
                    print("Failed to save log")
                }
                
                completion(inserted, errors)
            }
        } catch {
            if(self.syncLogDatabase.insert(log: Log(id: UUID().uuidString, date: Date.now, successCount: 0, errorCount: 1, type: importType, fileName: url.lastPathComponent))){
                print("Saved log")
            }else{
                print("Failed to save log")
            }
            
            completion(0, ["Error reading file"])
        }
    }
    
    private func saveHeartRate(date: Date, heartRate: Double, completion: @escaping (Bool, Error?) -> Void){
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let quantity = HKQuantity(unit: unit, doubleValue: heartRate)
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let heartRateSample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        
        heartRateEntryExists(date: date, heartRate: heartRate) { exists in
            if(!exists){
                self.healthStore.save(heartRateSample, withCompletion: completion)
            }else{
                completion(false, "Data already exists")
            }
        }
    }
    
    private func heartRateEntryExists(date: Date, heartRate: Double, completion: @escaping (Bool) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let calender = Calendar.current
        
        let predicate = HKQuery.predicateForSamples(withStart: calender.date(byAdding: .minute, value: -1, to: date), end: calender.date(byAdding: .minute, value: 1, to: date))
        
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: sortDescriptors) { query, results, error in
            
            if(error == nil && results != nil){
                for result in results!{
                    let sample = result as! HKQuantitySample
                    
                    if(sample.startDate == date){
                        if(sample.quantity.doubleValue(for: HKUnit(from: "count/min")) == heartRate){
                            completion(true)
                            return
                        }
                    }
                }
            }
            
            completion(false)
        }
        
        healthStore.execute(query)
    }
}
