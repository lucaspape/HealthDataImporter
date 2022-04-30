//
//  SelectDataTypeController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class SelectDataTypeController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var tableView: UITableView!
    private var reuseIdentifier = "cell"
    
    private var datatypes = Util.datatypes
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Select Datatype"
        
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        setupConstraints()
    }
    
    private func setupConstraints(){
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.setNeedsLayout()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        datatypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)!
        
        let datatype = self.datatypes[indexPath.row]
        
        cell.textLabel?.text = datatype.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let datatype = self.datatypes[indexPath.row]
        
        let importFromController = ImportFromController()
        importFromController.datatype = datatype
        navigationController?.pushViewController(importFromController, animated: true)
    }
}
