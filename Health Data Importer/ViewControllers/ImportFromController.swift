//
//  ImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import UniformTypeIdentifiers

class ImportFromController: UIViewController, UIDocumentPickerDelegate, UITableViewDelegate, UITableViewDataSource {
    private var tableView: UITableView!
    
    private var reuseIdentifier = "cell"
    
    var datatype: Datatype?
    
    private var importSources = Util.importSources
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Import From"
        
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
        importSources.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)!
        
        let importSource = self.importSources[indexPath.row]
        
        cell.textLabel?.text = importSource.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let importSource = self.importSources[indexPath.row]
        
        switch importSource.identifier {
        case "files":
            showFilePicker()
        case "url":
            let urlInputController = URLInputController()
            urlInputController.datatype = datatype
            navigationController?.pushViewController(urlInputController, animated: true)
        default:
            print("Option not found")
        }
        
        tableView.reloadData()
    }
    
    func showFilePicker(){
        let supportedTypes = UTType.types(tag: "csv",
                                     tagClass: UTTagClass.filenameExtension,
                                     conformingTo: nil)
        
        let pickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        pickerViewController.delegate = self
        pickerViewController.allowsMultipleSelection = false
        pickerViewController.shouldShowFileExtensions = true
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let configureImportController = ConfigureImportController()
        configureImportController.datatype = datatype
        configureImportController.urls = urls
        
        navigationController?.pushViewController(configureImportController, animated: true)
    }
}
