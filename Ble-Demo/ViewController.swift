//
//  ViewController.swift
//  Ble-Demo
//
//  Created by Bari Abdul on 7/19/18.
//  Copyright © 2018 Bari Abdul. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ViewController: UIViewController {
    
    public enum AppError: Error {
        case dataCharacteristicNotFound
        case enabledCharacteristicNotFound
        case updateCharacteristicNotFound
        case serviceNotFound
        case invalidState
        case resetting
        case poweredOff
        case unknown
    }
    
    var dataCharacteristic: Characteristic?
    

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
        let serviceUUID = CBUUID(string: "ec00")
        var peripheral: Peripheral?
        let dataCharacteristicUUID = CBUUID(string: "ec00")
        
        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralManagerKey" as NSString])
        let stateChangeFuture = manager.whenStateChanges()
        let scanFuture = stateChangeFuture.flatMap { (state) -> FutureStream<Peripheral> in
            switch state {
            case .unauthorized:
                throw AppError.invalidState
            case .unknown:
                throw AppError.unknown
            case .unsupported:
                throw AppError.invalidState
            case .resetting:
                throw AppError.resetting
            case .poweredOff:
                throw AppError.poweredOff
            case .poweredOn:
                DispatchQueue.main.async {
                    self.connectionStatusLabel.text = "Start Scanning"
                }
                return manager.startScanning(forServiceUUIDs: [serviceUUID])
            }
        }
        
        scanFuture.onFailure { (error) in
            guard let appError = error as? AppError else { return }
            
            switch appError {
            case .invalidState:
                break
            case .resetting:
                manager.reset()
            case .poweredOff:
                break
            case .unknown:
                break
            default:
                break
            }
        }
        
        let connectionFuture = scanFuture.flatMap { (p) -> FutureStream<Void> in
            manager.stopScanning()
            peripheral = p
            guard let peripheral = peripheral else { throw AppError.unknown }
            
            DispatchQueue.main.async {
                self.connectionStatusLabel.text = "Found peripheral \(peripheral.identifier.uuidString). Trying to connect"
            }
            return peripheral.connect(connectionTimeout: 10, capacity: 5)
        }
        
        let discoveryFuture = connectionFuture.flatMap { (_) -> Future<Void> in
            guard let peripheral = peripheral else { throw AppError.unknown }
            
            return peripheral.discoverServices([serviceUUID])
            }.flatMap { (_) -> Future<Void> in
                guard let discoveredPeripheral = peripheral else { throw AppError.unknown }
                guard let service = discoveredPeripheral.services(withUUID: serviceUUID)?.first else { throw AppError.serviceNotFound }
                
                peripheral = discoveredPeripheral
                DispatchQueue.main.async {
                    self.connectionStatusLabel.text = "Discovered service \(service.uuid.uuidString). Trying to discover characteristics"
                }
                return service.discoverCharacteristics([dataCharacteristicUUID])
        }
        
        
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

