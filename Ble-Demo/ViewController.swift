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
        //loadingView.isHidden = true
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
        
        let dataFuture = discoveryFuture.flatMap { (_) -> Future<Void> in
            guard let discoveredPeripheral = peripheral else { throw AppError.unknown }
            guard let dataCharacteristic = discoveredPeripheral.services(withUUID: serviceUUID)?.first?.characteristics(withUUID: dataCharacteristicUUID)?.first else { throw AppError.dataCharacteristicNotFound }
            self.dataCharacteristic = dataCharacteristic
            
            DispatchQueue.main.async {
                self.connectionStatusLabel.text = "Discovered characteristic \(dataCharacteristic.uuid.uuidString). That's awesome!"
            }
            
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
                self.characteristicView.isHidden = false
            }
            self.read()
            
            return dataCharacteristic.startNotifying()
            }.flatMap { (_) -> FutureStream<Data?> in
                guard let discoveredPeripheral = peripheral else { throw AppError.unknown }
                guard let characteristic = discoveredPeripheral.services(withUUID: serviceUUID)?.first?.characteristics(withUUID: dataCharacteristicUUID)?.first else { throw AppError.dataCharacteristicNotFound }
                
                return characteristic.receiveNotificationUpdates(capacity: 10)
        }
        
        dataFuture.onSuccess { (data) in
            let s = String(data: data!, encoding: .utf8)
            DispatchQueue.main.async {
                self.notifyLabel.text = "Notified value is \(String(describing: s))"
            }
        }
        
        dataFuture.onFailure { (error) in
            switch error {
            case PeripheralError.disconnected:
                peripheral?.reconnect()
            case AppError.serviceNotFound:
                break
            case AppError.dataCharacteristicNotFound:
                break
            default:
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onWritePressed(_ sender: Any) {
        self.write()
    }
    
    @IBAction func onRefreshPressed(_ sender: Any) {
        self.read()
    }
    
    func read() {
        let readFuture = self.dataCharacteristic?.read(timeout: 5)
        readFuture?.onSuccess(completion: { (_) in
            let s = String(data: (self.dataCharacteristic?.dataValue)!, encoding: .utf8)
            
            DispatchQueue.main.async {
                self.readValueLabel.text = "Read value is \(String(describing: s))"
            }
        })
        readFuture?.onFailure(completion: { (_) in
            self.readValueLabel.text = "Error while reading"
        })
    }
    
    func write() {
        self.valueToWriteTextField.resignFirstResponder()
        guard let text = self.valueToWriteTextField.text else { return }
        
        let writeFuture = self.dataCharacteristic?.write(data: text.data(using: .utf8)!)
        writeFuture?.onSuccess(completion: { (_) in
            print("Write Success")
        })
        writeFuture?.onFailure(completion: { (e) in
            print("Write Failure")
        })
    }
}

