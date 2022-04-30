//
//  URLInputController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 28.04.22.
//

import UIKit

class URLInputController: UIViewController {
    var datatype: Datatype?
    
    private var setupSync = false
    
    private var descriptionLabel: UILabel!
    
    private var urlInput: UITextField!
    
    private var syncSwitchLabel: UILabel!
    private var syncSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "URL Input"
        
        addNextButton()
        
        descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Please input your URL. You can use the variables {CURRENT_DATE} for todays date and {LAST_DATE} for yesterdays date"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = UIColor.label
        
        urlInput = UITextField()
        urlInput.translatesAutoresizingMaskIntoConstraints = false
        urlInput.placeholder = "http://example.com/{LAST_DATE}.csv"
        urlInput.textColor = UIColor.label
        urlInput.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        syncSwitchLabel = UILabel()
        syncSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        syncSwitchLabel.text = "Setup automatic sync"
        syncSwitchLabel.textColor = UIColor.label
        
        syncSwitch = UISwitch()
        syncSwitch.translatesAutoresizingMaskIntoConstraints = false
        syncSwitch.addTarget(self, action: #selector(syncSwitchChanged), for: .valueChanged)
        syncSwitch.setOn(setupSync, animated: false)
        
        view.addSubview(descriptionLabel)
        view.addSubview(urlInput)
        view.addSubview(syncSwitchLabel)
        view.addSubview(syncSwitch)
        
        setupConstraints()
    }

    private func setupConstraints(){
        descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        descriptionLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        urlInput.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10).isActive = true
        urlInput.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        syncSwitchLabel.topAnchor.constraint(equalTo: urlInput.bottomAnchor, constant: 10).isActive = true
        syncSwitchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        syncSwitch.topAnchor.constraint(equalTo: syncSwitchLabel.topAnchor).isActive = true
        syncSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.setNeedsLayout()
    }
    
    private func addNextButton(){
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "right"), for: .normal) // 22x22 1x, 44x44 2x, 66x66 3x
        button.setTitle("Next", for: .normal)
        button.sizeToFit()
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.setTitleColor(.systemGray, for: .disabled)
        button.addTarget(self, action: #selector(onNextButtonPressed), for: .touchUpInside)
        let nextBtn = UIBarButtonItem(customView: button)
        nextBtn.isEnabled = false
        let spaceBtn = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceBtn.width = -8// Change this value as per your need
        self.navigationItem.rightBarButtonItems = [spaceBtn, nextBtn]
    }
    
    @objc private func onNextButtonPressed(){
        Util.showLoading(controller: self, message: "Downloading file...")
        
        Util.downloadFile(urlString: urlInput.text!) { success, url, error in
            Util.hideLoading(controller: self) {
                if(success){
                    let configureImportController = ConfigureImportController()
                    configureImportController.datatype = self.datatype
                    configureImportController.urls = [url!]
                    configureImportController.setupSync = self.setupSync
                    configureImportController.urlString = self.urlInput.text!
                    
                    self.navigationController?.pushViewController(configureImportController, animated: true)
                }else if(error != nil){
                    Util.showAlert(controller: self, title: "Error while downloading", message: error!.localizedDescription) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }else{
                    Util.showAlert(controller: self, title: "Error while downloading", message: "Unknown error") {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func textFieldChanged(){
        checkInputs()
    }
    
    @objc private func syncSwitchChanged(){
        setupSync = syncSwitch.isOn
    }
    
    private func checkInputs(){
        var valid = true
        
        if(urlInput.text?.count == 0){
            valid = false
        }
        
        navigationItem.rightBarButtonItems?[1].isEnabled = valid
    }
}
