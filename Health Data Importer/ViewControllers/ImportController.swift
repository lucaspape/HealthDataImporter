//
//  ImportController.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 25.04.22.
//

import UIKit

class ImportController: UIViewController {
    private var placeholder: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeholder = UILabel()
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.text = "PLACEHOLDER"
        placeholder.textColor = UIColor.label
        placeholder.backgroundColor = UIColor.white
        
        view.addSubview(placeholder)
        
        setupConstraints()
    }
    
    private func setupConstraints(){
        placeholder.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        placeholder.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        placeholder.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        placeholder.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.setNeedsLayout()
    }
}
