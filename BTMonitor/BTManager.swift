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
import XCGLogger

class BTManager: NSObject {
    static let sharedManager = BTManager()
    
    static let connectionNotification = NSNotification.Name("CONNECTION_NOTIFICATION")
    
    var connectedState: Bool {
        return self.connectedPeripherals.count > 0
    }
    
    var connectedDeviceCount: Int {
        return self.connectedPeripherals.count
    }
    
    var reconnectMode: Bool = false
    
    fileprivate var cbCentral: CBCentralManager!
    fileprivate var connectedPeripherals = Set<CBPeripheral>()
    fileprivate var targetPeripherals = Set<CBPeripheral>()
    fileprivate var characteristics = [CBPeripheral:CBCharacteristic]()
    
    private let queue = DispatchQueue(label: "BTQueue")
    
    fileprivate let serviceUUID = CBUUID(string: "36353433-3231-3039-3837-363534333231")
    fileprivate let characteristicUUID = CBUUID(string: "36353433-3231-3039-3837-363534336261")
    
    private override init() {
        
        super.init()
        
        cbCentral = CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionRestoreIdentifierKey: " Central "])
        
    }
    
    func startScan() {
        log?.info("Starting BT scan")
        self.cbCentral.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScan() {
        log?.info("Stopping BT scan")
        self.cbCentral.stopScan()
    }
    
    func sendConnectionNotification() {
        let nc = NotificationCenter.default
        
        nc.post(name: BTManager.connectionNotification, object: self, userInfo: ["STATE":self.connectedState,"CONNECTION":true])
    }
    
    func sendDisconnectionNotification() {
        let nc = NotificationCenter.default
        
        nc.post(name: BTManager.connectionNotification, object: self, userInfo: ["STATE":self.connectedState,"CONNECTION":false])
    }
    
    var log:XCGLogger?  {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.log
        } else {
            return nil
        }
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
                appDelegate.sendLocalNotification(title: "Scanning", body: "Starting Bluetooth Scan", color: .green)
            }
            self.startScan()
            
        case .unsupported: break
            
        case .unknown: break
            
        case .unauthorized: break
            
        case .resetting: break
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log?.info("Discovered peripheral \(peripheral.identifier)")
        self.targetPeripherals.insert(peripheral)
        log?.info("Initiating connection to \(peripheral)")
        central.connect(peripheral, options: nil)
        
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        log?.info("Connected to \(peripheral)")
        self.connectedPeripherals.insert(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([])
        self.sendConnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        
        if let error = error {
            log?.error("Disconnected from \(peripheral) with error: \(error)")
            
        } else {
            log?.warning("Disconnected from \(peripheral)")
        }
        
        self.connectedPeripherals.remove(peripheral)
        self.characteristics[peripheral] = nil
        
        if  self.targetPeripherals.contains(peripheral) && reconnectMode {
            
            log?.info("Initiating reconnection to \(peripheral)")
            central.connect(peripheral, options: nil)
        } else if !reconnectMode {
            self.stopScan()
            self.startScan()
        }
        
        self.sendDisconnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        if let error = error {
            log?.error("Failed to connect with error:\(error)")
        } else {
            log?.error("Failed to connect")
        }
        
        self.sendDisconnectionNotification()
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            
            for peripheral in peripherals {
                
                log?.info("Restored peripheral \(peripheral)")
                if peripheral.state == .connected {
                    self.targetPeripherals.insert(peripheral)
                    self.connectedPeripherals.insert(peripheral)
                    self.sendConnectionNotification()
                }
            }
        }
        
    }
    
}

// MARK: - CBPeripheralDelegate

extension BTManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log?.info("Discovered services")
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        log?.info("Discovered characteristics")
        for characteristic in service.characteristics ?? [] {
            print(characteristic)
            if characteristic.uuid == self.characteristicUUID {
                self.characteristics[peripheral] = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            var values = [UInt8](repeating:0, count:data.count)
            data.copyBytes(to: &values, count: data.count)
            print("\(values[0])")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        log?.debug("Services changed")
        
        /*  if targetPeripherals.contains(peripheral) {
         for service in invalidatedServices {
         if service.uuid == serviceUUID {
         if self.connectedPeripherals.contains(peripheral) {
         self.targetPeripherals.remove(peripheral)
         self.cbCentral.cancelPeripheralConnection(peripheral)
         }
         }
         }
         } else {
         self.targetPeripherals.insert(peripheral)
         self.cbCentral.connect(peripheral, options: nil)
         }*/
    }
}
