//
//  SelectDataTypeController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit
import HealthKit

class SelectDataTypeController: UIViewController {
    private let options:[Datatype] = [Datatype(name: "Heart-Rate", identifier: .heartRate)]
    
    private var stack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.title = "Select Datatype"
        
        var subViews: [UIView] = []
        
        for (index, option) in options.enumerated() {
            let button = UIButton()
            button.setTitle(option.name, for: .normal)
            button.setTitleColor(UIColor.label, for: .normal)
            button.addTarget(self, action: #selector(onOptionClick), for: .touchUpInside)
            button.tag = index
            
            subViews.append(button)
        }
        
        stack = UIStackView(arrangedSubviews: subViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        
        view.addSubview(stack)
        
        setupConstraints()
    }
    
    private func setupConstraints(){
        stack.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        
        view.setNeedsLayout()
    }
    
    @objc private func onOptionClick(sender: UIButton){
        let option = options[sender.tag]
        
        switch option.identifier {
            case .heartRate:
                let importFromController = ImportFromController()
                importFromController.datatype = option
                navigationController?.pushViewController(importFromController, animated: true)
            default:
                print("Option not found")
        }
    }
}
