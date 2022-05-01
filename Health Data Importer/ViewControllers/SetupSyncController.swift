//
//  SetupSyncController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 28.04.22.
//

import UIKit

class SetupSyncController: UIViewController {
    var datatype: Datatype?
    var urlString: String?
    var dataStructure: DataStructure?
    
    let healthManager = HealthManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Setup sync"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Util.showLoading(controller: self, message: "Requesting health data access...")
        
        healthManager.requestHealthAccess { success, error in
            Util.hideLoading(controller: self) {
                if(success){
                    do {
                        switch(self.datatype!.identifier){
                            case .heartRate:
                            try self.healthManager.addSync(sync: HeartRateSync(urlString: self.urlString!, dataStructure: self.dataStructure! as! HeartRateDataStructure))
                            default:
                                Logger.log(msg: "Unknown datatype")
                        }
                        
                        Util.showAlert(controller: self, title: "Setup sync", message: "Sync is set up") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }catch{
                        Util.showAlert(controller: self, title: "Error", message: "Failed to set up sync") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }else{
                    var error = error
                    
                    if(error == nil){
                        error = "Unknown error"
                    }
                    
                    Util.showAlert(controller: self, title: "Error accessing health data", message: "There was an error accessing the health data: " + error!.localizedDescription) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
}
