//
//  BackgroundScheduler.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 01.05.22.
//

import CoreLocation

struct BackgroundTask {
    let run: () -> Void
    let after: Date
}

class BackgroundScheduler: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager!
    
    private var tasks: [BackgroundTask] = []
    
    override init(){
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        enableBackgroundUpdate()
    }
    
    private func enableBackgroundUpdate(){
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("Always location authorized")
        }else{
            print("Always location not authorized")
        }
        
        enableBackgroundUpdate()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for (i, task) in tasks.enumerated() {
            if(Date.now.timeIntervalSince1970 > task.after.timeIntervalSince1970){
                tasks.remove(at: i)
                task.run()
                
                break
            }
        }
    }
    
    func registerTask(task: BackgroundTask){
        tasks.append(task)
    }
    
    func clearTasks(){
        tasks = []
    }
}
