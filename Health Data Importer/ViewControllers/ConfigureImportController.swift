//
//  ConfigureImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class ConfigureImportController: UIViewController {
    private var inputs: [ConfigureInput]!
    
    var datatype: Datatype?
    var urls: [URL]?
    var setupSync: Bool?
    var urlString: String?
    
    private var labels: [InputIdentifier: UILabel] = [:]
    private var textFields: [InputIdentifier: UITextField] = [:]
    private var openColumnPickers: [InputIdentifier: UIButton] = [:]
    private var columnPickerControllers: [InputIdentifier: ColumnConfigurationController] = [:]
    private var coloumnPickerTags: [Int: InputIdentifier] = [:]
    private var columnPickerResults: [InputIdentifier: [Int]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Configure Import"
        addNextButton()
        
        inputs = Util.configurationInputs[datatype!.identifier]!
        
        do {
            let data = try String(contentsOfFile: urls![0].path)
            
            let lines = data.split(separator: "\n")
            
            if(lines.count > 1){
                var tag = 0
                
                for input in inputs {
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.text = input.label
                    label.textColor = UIColor.label
                    labels[input.identifier] = label
                    view.addSubview(label)
                    
                    if(input is TextConfigureInput){
                        let input = input as! TextConfigureInput
                        
                        let textField = UITextField()
                        textField.translatesAutoresizingMaskIntoConstraints = false
                        textField.placeholder = input.placeholder
                        textField.text = input.placeholder
                        textField.keyboardType = input.keyboardType
                        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
                        textFields[input.identifier] = textField
                        view.addSubview(textField)
                    }else if(input is ColumnPickerInput){
                        let input = input as! ColumnPickerInput
                        
                        let openColumnPickerButton = UIButton()
                        openColumnPickerButton.translatesAutoresizingMaskIntoConstraints = false
                        openColumnPickerButton.setTitle("Set column number", for: .normal)
                        openColumnPickerButton.setTitleColor(UIColor.label, for: .normal)
                        openColumnPickerButton.tag = tag
                        coloumnPickerTags[tag] = input.identifier
                        tag += 1
                        openColumnPickerButton.addTarget(self, action: #selector(openColoumnPicker), for: .touchUpInside)
                        openColumnPickers[input.identifier] = openColumnPickerButton
                        view.addSubview(openColumnPickerButton)
                    }
                }
                
                setupConstraints()
            }else{
                Util.showAlert(controller: self, title: "Error", message: "File is empty") {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }catch{
            Util.showAlert(controller: self, title: "Error", message: "Error reading file") {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc private func openColoumnPicker(sender: UIButton){
        if(columnPickerControllers[coloumnPickerTags[sender.tag]!] == nil){
            columnPickerControllers[coloumnPickerTags[sender.tag]!] = ColumnConfigurationController()
        }
        
        var foundInput: ColumnPickerInput?
        
        for input in inputs {
            if(input.identifier == coloumnPickerTags[sender.tag]){
                foundInput = input as? ColumnPickerInput
            }
        }
        
        columnPickerControllers[coloumnPickerTags[sender.tag]!]!.multiSelect = foundInput?.multiSelect
        columnPickerControllers[coloumnPickerTags[sender.tag]!]!.subInputs = foundInput?.subInputs
        
        columnPickerControllers[coloumnPickerTags[sender.tag]!]!.label = foundInput?.label
        columnPickerControllers[coloumnPickerTags[sender.tag]!]!.urls = urls
        columnPickerControllers[coloumnPickerTags[sender.tag]!]!.onChange = {
            self.columnPickerResults[self.coloumnPickerTags[sender.tag]!] = self.columnPickerControllers[self.coloumnPickerTags[sender.tag]!]!.selectedRows
            
            self.openColumnPickers[self.coloumnPickerTags[sender.tag]!]?.setTitle("Preview: " + self.columnPickerControllers[self.coloumnPickerTags[sender.tag]!]!.getPreviewText(), for: .normal)
            
            self.checkInputs()
        }
        
        present(columnPickerControllers[coloumnPickerTags[sender.tag]!]!, animated: true)
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
    
    private func setupConstraints(){
        var previousUIView: UIView?
        
        for(i, input) in inputs.enumerated() {
            var topConstant:CGFloat = 10
            var topAnchor = view.topAnchor
            
            if(i == 0){
                topConstant = 100
            }else{
                topAnchor = previousUIView!.bottomAnchor
            }
            
            labels[input.identifier]!.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            labels[input.identifier]!.topAnchor.constraint(equalTo: topAnchor, constant: topConstant).isActive = true
            
            if(input is TextConfigureInput){
                textFields[input.identifier]!.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
                textFields[input.identifier]!.topAnchor.constraint(equalTo: labels[input.identifier]!.bottomAnchor, constant: 5).isActive = true
                previousUIView = textFields[input.identifier]!
            }else if(input is ColumnPickerInput){
                openColumnPickers[input.identifier]!.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
                openColumnPickers[input.identifier]!.topAnchor.constraint(equalTo: labels[input.identifier]!.bottomAnchor, constant: 5).isActive = true
                previousUIView = openColumnPickers[input.identifier]!
            }
        }
        
        view.setNeedsLayout()
    }
    
    @objc private func textFieldChanged(){
        checkInputs()
    }
    
    private func checkInputs(){
        var valid = true
        
        for (input) in inputs {
            if(input is TextConfigureInput){
                if(textFields[input.identifier]?.text?.count == 0){
                    valid = false
                }
            }else if(input is ColumnPickerInput){
                if(columnPickerResults[input.identifier]?.count == 0){
                    valid = false
                }
                
                let controller = columnPickerControllers[input.identifier]
                
                if(controller != nil){
                    for subInput in controller!.subInputs! {
                        if(subInput is TextConfigureInput){
                            if(controller!.textFields[subInput.identifier]?.text?.count == 0){
                                valid = false
                            }
                        }
                    }
                }else{
                    valid = false
                }
            }
        }

        navigationItem.rightBarButtonItems?[1].isEnabled = valid
    }
    
    @objc private func onNextButtonPressed(){
        var values: [InputIdentifier:Any] = [:]
        
        for (input) in inputs {
            if(input is TextConfigureInput){
                values[input.identifier] = textFields[input.identifier]!.text
            }else if(input is ColumnPickerInput){
                let input = input as! ColumnPickerInput
                
                values[input.identifier] = columnPickerResults[input.identifier]
                
                for subInput in input.subInputs {
                    let controller = columnPickerControllers[input.identifier]!
                    values[subInput.identifier] = controller.textFields[subInput.identifier]?.text
                }
            }
        }
        
        do {
            let dataStructure = try Util.inputListToDataStructure(input: values, datatype: datatype!)
            
            if(setupSync == true){
                let setupSyncController = SetupSyncController()
                setupSyncController.dataStructure = dataStructure
                setupSyncController.datatype = datatype
                setupSyncController.urlString = urlString
                
                navigationController?.pushViewController(setupSyncController, animated: true)
            }else{
                let runImportController = RunImportController()
                runImportController.dataStructure = dataStructure
                runImportController.urls = urls
                runImportController.datatype = datatype
                
                navigationController?.pushViewController(runImportController, animated: true)
            }
        }catch{
            Util.showAlert(controller: self, title: "Error parsing input", message: "There was a parse error. Please check your inputs") {
                
            }
        }
    }
}
