//
//  ViewController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import MobileCoreServices
import HealthKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var tableView: UITableView!
    
    private var reuseIdentifier = "cell"
    
    private let logDatabase = SyncLogDatabase()
    private let syncDatabase = SyncDatabase()
    
    private var syncs: [SyncWithId] = []
    private var logs: [Log] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        navigationItem.rightBarButtonItem = addItem
        navigationItem.title = "Health Data Importer"
        
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        setupConstraints()
        
        if(Util.backgroundScheduler == nil){
            Util.backgroundScheduler = BackgroundScheduler()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData()
        
        tableView.reloadData()
    }
    
    private func loadData(){
        syncs = syncDatabase.get()
        logs = logDatabase.get()
    }
    
    private func setupConstraints(){
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.setNeedsLayout()
    }
    
    @objc func addButtonPressed(){
        let selectDataTypeController = SelectDataTypeController()
        
        navigationController?.pushViewController(selectDataTypeController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0){
            return syncs.count
        }else if(section == 1){
            return logs.count
        }else{
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)!
        
        if(indexPath.section == 0){
            let sync = self.syncs[indexPath.row]
            
            if(sync.sync is HeartRateSync){
                let sync = sync.sync as! HeartRateSync
                
                cell.textLabel?.text = sync.urlString
            }
        }else if(indexPath.section == 1){
            let log = self.logs[indexPath.row]
            
            cell.textLabel?.text = log.fileName + " - inserted: " + String(log.successCount) + " - errors: " + String(log.errorCount)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(indexPath.section == 0){
            if (editingStyle == .delete) {
                let sync = syncs[indexPath.row]
                
                if(syncDatabase.delete(id: sync.id)){
                    loadData()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }else{
                    Util.showAlert(controller: self, title: "Error", message: "Coudl not remove sync") {}
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "Syncs"
        }else if(section == 1){
            return "Logs"
        }
        
        return nil
    }
}
