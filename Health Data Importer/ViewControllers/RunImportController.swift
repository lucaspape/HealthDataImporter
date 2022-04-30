//
//  RunImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit

class RunImportController:UIViewController {
    var dataStructure: DataStructure?
    var urls: [URL]?
    var datatype: Datatype?
    
    let healthManager = HealthManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Importing"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Util.showLoading(controller: self, message: "Requesting health data access...")
        
        healthManager.requestHealthAccess { success, error in
            Util.hideLoading(controller: self) {
                if(success){
                    Util.showLoading(controller: self, message: "Importing data...")
                    
                    self.healthManager.importFiles(files: self.urls!, datatype: self.datatype!, dataStructure: self.dataStructure!, importType: "manual") { success, count, errors in
                        Util.hideLoading(controller: self) {
                            if(success){
                                Util.showAlert(controller: self,title: "Imported data successfully", message: "Successfully inserted " + String(count) + " objects") {
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }else{
                                let error = "There were " + String(errors.count) + " errors. " + String(count) + " objects imported successfully"
                                
                                print(errors)
                                
                                Util.showAlert(controller: self, title: "Error importing data", message: error) {
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
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
