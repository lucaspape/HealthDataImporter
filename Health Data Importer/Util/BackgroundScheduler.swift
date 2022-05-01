//
//  BackgroundScheduler.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 01.05.22.
//

import CoreLocation

struct BackgroundTask {
    let run: () -> Void
    let after: Double
}

class BackgroundScheduler: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    
    var tasks: [BackgroundTask] = []
    
    override init(){
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("authorized")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentTimestamp = Date.now.timeIntervalSince1970
        
        for (i, task) in tasks.enumerated() {
            if(currentTimestamp > task.after){
                tasks.remove(at: i)
                task.run()
                
                break
            }
        }
    }
}
