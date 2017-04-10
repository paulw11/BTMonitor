//
//  BTManager.swift
//  BTMonitor
//
//  Created by Paul Wilkinson on 9/4/17.
//  Copyright © 2017 Paul Wilkinson. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class BTManager: NSObject {
static let sharedManager = BTManager()
    
    static let connectionNotification = NSNotification.Name("CONNECTION_NOTIFICATION")
    
    var connectedState: Bool {
        return self.connectedPeripheral != nil
    }
    
    fileprivate var cbCentral: CBCentralManager!
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var targetPeripheral: CBPeripheral?
    fileprivate var characteristic: CBCharacteristic?
    
    private let queue = DispatchQueue(label: "BTQueue")
    
    fileprivate let serviceUUID = CBUUID(string: "36353433-3231-3039-3837-363534333231")
    fileprivate let characteristicUUID = CBUUID(string: "36353433-3231-3039-3837-363534336261")
    
    private override init() {
        
        super.init()
        
        cbCentral = CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionRestoreIdentifierKey: " Central "])

    }
    
    func startScan() {
        
        self.cbCentral.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
    }
    
    func sendConnectionNotification() {
        let nc = NotificationCenter.default
        
        nc.post(name: BTManager.connectionNotification, object: self, userInfo: ["STATE":self.connectedState])
    }
 
  
}

// MARK: - CBCentralManagerDelegate

extension BTManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff: break
            
        case .poweredOn:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            DispatchQueue.main.async {
                appDelegate.sendLocalNotification(title: "Scanning", body: "Starting Bluetooth Scan")
            }
            self.startScan()
            
        case .unsupported: break
            
        case .unknown: break
            
        case .unauthorized: break
            
        case .resetting: break
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral \(peripheral.identifier)")
        self.targetPeripheral = peripheral
        central.connect(peripheral, options: nil)

    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        central.stopScan()
        self.sendConnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        self.connectedPeripheral = nil
        self.characteristic = nil
        self.startScan()
     /*   if let target = self.targetPeripheral {
            central.connect(target, options: nil)
        }*/
        self.sendConnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect")
        self.connectedPeripheral = nil
        self.characteristic = nil
        self.startScan()
        self.sendConnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            
            for peripheral in peripherals {
                
                print("Restored peripheral \(peripheral)")
                if peripheral.state == .connected {
                    self.targetPeripheral = peripheral
                    self.connectedPeripheral = peripheral
                    self.sendConnectionNotification()
                }
            }
        }
        
    }
    
}

// MARK: - CBPeripheralDelegate

extension BTManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services")
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics")
        for characteristic in service.characteristics ?? [] {
            print(characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            var values = [UInt8](repeating:0, count:data.count)
            data.copyBytes(to: &values, count: data.count)
            print("\(values[0])")
        }
    }
}
