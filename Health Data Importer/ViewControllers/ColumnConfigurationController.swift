//
//  ColumnConfigurationController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit

class ColumnConfigurationController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var label: String?
    var urls: [URL]?
    var subInputs: [ConfigureInput]?
    var multiSelect: Bool?
    
    private var values: [Substring.SubSequence] = []
    private var pickerComponentSelections: [Int: Int] = [:]
    
    private var titleLabel: UILabel!
    
    private var picker: UIPickerView!
    private var pickerData: [String] = []
    
    private var addAdditionalButton: UIButton!
    private var removeAdditionalButton: UIButton!
    
    private var previewLabel: UILabel!
    private var preview: UILabel!
    
    var onChange: () -> Void = {
        
    }
    
    private var labels: [InputIdentifier: UILabel] = [:]
    var textFields: [InputIdentifier: UITextField] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        do {
            titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = "Select " + label!
            titleLabel.textColor = UIColor.label
            
            let data = try String(contentsOfFile: urls![0].path)
            
            let lines = data.split(separator: "\n")
            
            let testLine = lines[1]
            
            values = testLine.split(separator: ",")
            
            for i in 1...values.count {
                pickerData.append(String(i))
            }
            
            picker = UIPickerView()
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.delegate = self
            picker.dataSource = self
            
            if(multiSelect!){
                addAdditionalButton = UIButton()
                addAdditionalButton.translatesAutoresizingMaskIntoConstraints = false
                addAdditionalButton.setTitle("Add column", for: .normal)
                addAdditionalButton.setTitleColor(UIColor.label, for: .normal)
                addAdditionalButton.addTarget(self, action: #selector(addAdditional), for: .touchUpInside)
                
                removeAdditionalButton = UIButton()
                removeAdditionalButton.translatesAutoresizingMaskIntoConstraints = false
                removeAdditionalButton.setTitle("Remove column", for: .normal)
                removeAdditionalButton.setTitleColor(UIColor.label, for: .normal)
                removeAdditionalButton.addTarget(self, action: #selector(removeAdditional), for: .touchUpInside)
            }
            
            previewLabel = UILabel()
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            previewLabel.textColor = UIColor.label
            previewLabel.text = label! + " preview"
            
            preview = UILabel()
            preview.translatesAutoresizingMaskIntoConstraints = false
            preview.textColor = UIColor.label
            preview.text = getPreviewText()
            onChange()
            
            view.addSubview(titleLabel)
            view.addSubview(picker)
            
            if(multiSelect!){
                view.addSubview(addAdditionalButton)
                view.addSubview(removeAdditionalButton)
            }
            
            view.addSubview(previewLabel)
            view.addSubview(preview)
            
            for input in subInputs! {
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
                }
            }
            
            setupConstraints()
        } catch {
            print("error reading file")
        }
    }
    
    private func setupConstraints(){
        titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        
        picker.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        picker.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        if(multiSelect!){
            addAdditionalButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 10).isActive = true
            addAdditionalButton.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 5).isActive = true
            
            removeAdditionalButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 10).isActive = true
            removeAdditionalButton.topAnchor.constraint(equalTo: addAdditionalButton.bottomAnchor, constant: 5).isActive = true
            
            previewLabel.topAnchor.constraint(equalTo: removeAdditionalButton.bottomAnchor, constant: 10).isActive = true
        }else{
            previewLabel.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 10).isActive = true
        }
        
        previewLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 10).isActive = true
        
        preview.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 15).isActive = true
        preview.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 5).isActive = true
        
        var previousUIView: UIView?
        
        for(i, input) in subInputs!.enumerated() {
            var topAnchor = preview.bottomAnchor
            
            if(i != 0){
                topAnchor = previousUIView!.bottomAnchor
            }
            
            labels[input.identifier]!.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            labels[input.identifier]!.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            
            if(input is TextConfigureInput){
                textFields[input.identifier]!.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
                textFields[input.identifier]!.topAnchor.constraint(equalTo: labels[input.identifier]!.bottomAnchor, constant: 5).isActive = true
                previousUIView = textFields[input.identifier]!
            }
        }
        
        view.setNeedsLayout()
    }
    
    @objc private func textFieldChanged(){
        onChange()
    }
    
    var numberOfColoumns = 1
    
    @objc private func addAdditional(){
        numberOfColoumns+=1
        picker.reloadAllComponents()
        preview.text = getPreviewText()
        onChange()
    }
    
    @objc private func removeAdditional(){
        if(numberOfColoumns > 1){
            numberOfColoumns-=1
        }
        
        picker.reloadAllComponents()
        preview.text = getPreviewText()
        onChange()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numberOfColoumns
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerComponentSelections[component] = row
        
        preview.text = getPreviewText()
        onChange()
    }
    
    func getPreviewText() -> String {
        var previewText = ""
        
        let rows = selectedRows
        
        for row in rows {
            previewText += values[row] + Util.dateSeperator
        }
        
        previewText = String(previewText.dropLast())
        
        return previewText
    }
    
    var selectedRows: [Int] {
        get {
            var selectedRows:[Int] = []
            
            for i in 0...numberOfColoumns-1 {
                let selected = pickerComponentSelections[i]
                
                if(selected != nil){
                    selectedRows.append(selected!)
                }else{
                    selectedRows.append(0)
                }
            }
            
            return selectedRows
        }
    }
}
