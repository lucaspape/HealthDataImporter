//
//  ConfigureImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class ConfigureImportController: UIViewController {
    var datatype: Datatype?
    var urls: [URL]?
    
    private var labels: [UILabel] = []
    private var textFields: [UITextField] = []
    
    let inputs = [ConfigureInput(label: "Data position", placeholder: "2"), ConfigureInput(label: "Date positions", placeholder: "0,1"), ConfigureInput(label: "Date format", placeholder: "dd-MM-yy_HH-mm"), ConfigureInput(label: "Date seperator", placeholder: "_")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Configure Import"
        addNextButton()
        
        for input in inputs {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = input.label
            label.textColor = UIColor.label
            
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.placeholder = input.placeholder
            textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
            
            labels.append(label)
            textFields.append(textField)
        }
        
        for (i, label) in labels.enumerated() {
            view.addSubview(label)
            view.addSubview(textFields[i])
        }
        
        setupConstraints()
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
        for(i, label) in labels.enumerated() {
            var topConstant:CGFloat = 10
            var topAnchor = view.topAnchor
            
            if(i == 0){
                topConstant = 100
            }else{
                topAnchor = textFields[i-1].bottomAnchor
            }
            
            label.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: topConstant).isActive = true
            textFields[i].widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            textFields[i].topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5).isActive = true
        }
        
        view.setNeedsLayout()
    }
    
    @objc private func textFieldChanged(){
        checkTextFields()
    }
    
    private func checkTextFields(){
        var valid = true
        
        for textField in textFields {
            if(textField.text?.count == 0){
                valid = false
            }
        }
        
        navigationItem.rightBarButtonItems?[1].isEnabled = valid
    }
    
    @objc private func onNextButtonPressed(){
        var values: [String] = []
        
        for textField in textFields {
            values.append(textField.text!)
        }
        
        let dataStructure: Any?
        
        switch(datatype!.identifier){
            case .heartRate:
                print(values)
                let dataPosition = Int(String(values[0]))!
                var datePositions: [Int] = []
            
                for position in values[1].split(separator: ","){
                    datePositions.append(Int(String(position))!)
                }
            
                let dateFormat = values[2]
                let dateSeperator = values[3]
            
                dataStructure = HeartRateDataStructure(dateFormat: dateFormat, datePositions: datePositions, dateSeperator: dateSeperator, dataPosition: dataPosition, skipFirstLine: true)
                
            default:
                dataStructure = nil
                print("Does not suport identifier")
        }
        
        let runImportController = RunImportController()
        runImportController.dataStructure = dataStructure
        runImportController.urls = urls
        runImportController.datatype = datatype
        
        navigationController?.pushViewController(runImportController, animated: true)
    }
}
