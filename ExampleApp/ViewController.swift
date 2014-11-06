//
//  ViewController.swift
//  ExampleApp
//
//  Created by George Shank on 11/4/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    var central = CBCentralManager()
    var peripheral = CBPeripheralManager()
    var characterstic = CBMutableCharacteristic()
    var service = CBMutableService()
    let uuid = CBUUID(string: "180D")
    
    
    @IBOutlet var messageInputField: UITextField!
    @IBAction func sendMessageButton() {
        sendMessage(messageInputField.text)
    }
    
    func sendMessage(incomingMessage: String?) {
        var message = "No message to send"
        
        if let maybeMessage = incomingMessage {
            if maybeMessage.utf16Count > 0 {
                message = maybeMessage
            }
        }
        
        NSLog("%@", message)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        sendMessage(textField.text)
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        central = CBCentralManager(delegate: self, queue: nil)
        peripheral = CBPeripheralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Central Manager
    func startScanning() {
        central.scanForPeripheralsWithServices([uuid], options: nil)
    }
    
    // MARK: Central Manager Delegate
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
            
        case .PoweredOff:
            println("CoreBluetooth BLE hardware is powered off")
            break
        case .PoweredOn:
            println("CoreBluetooth BLE hardware is powered on and ready")
            self.startScanning()
            break
        case .Resetting:
            println("CoreBluetooth BLE hardware is resetting")
            break
        case .Unauthorized:
            println("CoreBluetooth BLE state is unauthorized")
            break
        case .Unknown:
            println("CoreBluetooth BLE state is unknown")
            break
        case .Unsupported:
            println("CoreBluetooth BLE hardware is unsupported on this platform")
            break
            
        default:
            break
        }
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        print("Central Manager will restore state")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        NSLog("Discovered a peripheral: %@", peripheral)
        
        if peripheral.services != nil {
            println("Found some services on the peripheral")
            println(peripheral.services.count)
        }
    }
    
    // MARK: Peripheral Manager
    func startAdvertising() {
        characterstic = CBMutableCharacteristic(type: uuid, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Read | CBCharacteristicProperties.Indicate, value: nil, permissions: CBAttributePermissions.Readable | CBAttributePermissions.Writeable)
        
        service = CBMutableService(type: uuid, primary: true)
        
        service.characteristics = [characterstic]
        
        peripheral.addService(service)

        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [service.UUID]])
    }
    
    // MARK: Peripheral Manager Delegate
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error != nil {
            println("Error with advertising")
        } else {
            println("Started advertising")
        }
    }
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        switch peripheral.state {
            
        case .PoweredOff:
            println("CoreBluetooth BLE hardware is powered off")
            break
        case .PoweredOn:
            println("CoreBluetooth BLE hardware is powered on and ready")
            self.startAdvertising()
            break
        case .Resetting:
            println("CoreBluetooth BLE hardware is resetting")
            break
        case .Unauthorized:
            println("CoreBluetooth BLE state is unauthorized")
            break
        case .Unknown:
            println("CoreBluetooth BLE state is unknown")
            break
        case .Unsupported:
            println("CoreBluetooth BLE hardware is unsupported on this platform")
            break
            
        default:
            break
        }

    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        if error != nil {
            print("Got an error")
        }
        
        NSLog("Service added: %@", service)
    }
}

