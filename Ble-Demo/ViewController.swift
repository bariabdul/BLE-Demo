//
//  ViewController.swift
//  Ble-Demo
//
//  Created by Bari Abdul on 7/19/18.
//  Copyright © 2018 Bari Abdul. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var characteristicView: UIView!
    @IBOutlet weak var readValueLabel: UILabel!
    @IBOutlet weak var notifyLabel: UILabel!
    @IBOutlet weak var valueToWriteTextField: UITextField!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var statusIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadingView.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onWritePressed(_ sender: Any) {
        
    }
    
    @IBAction func onRefreshPressed(_ sender: Any) {
        
    }
}

