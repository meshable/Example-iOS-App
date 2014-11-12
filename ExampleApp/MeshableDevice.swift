//
//  MeshableDevice.swift
//  ExampleApp
//
//  Created by George Shank on 11/11/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import CoreBluetooth

protocol MeshableDeviceDelegate {
    func bluetoothReady()
    
    func bluetoothNotReady(reason: String, bluetoothState: CBCentralManagerState)
}

class MeshableDevice: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    var central: CBCentralManager
    var delegate: MeshableDeviceDelegate?
    
    override init() {
        super.init()
    }
    
    // MARK: Central Manager
    func startScanning(uuids: [CBUUID]) {
        central.scanForPeripheralsWithServices(uuids, options: nil)
    }
    
    // MARK: Central Manager Delegate
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
            
        case .PoweredOff:
            delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is powered off", bluetoothState: .PoweredOff)
            break
        case .PoweredOn:
            delegate?.bluetoothReady()
            break
        case .Resetting:
            delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is resetting", bluetoothState: .Resetting)
            break
        case .Unauthorized:
            delegate?.bluetoothNotReady("CoreBluetooth BLE state is unauthorized", bluetoothState: .Unauthorized)
            break
        case .Unknown:
            delegate?.bluetoothNotReady("CoreBluetooth BLE state is unknown", bluetoothState: .Unknown)
            break
        case .Unsupported:
            delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is unsupported on this platform", bluetoothState: .Unsupported)
            break
            
        default:
            break
        }
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        print("Central Manager will restore state")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Discovered a peripheral")
        
        //Seems we need to retain the discovered peripheral to successfully connect to it
        self.discoveredPeripheral.append(peripheral)
        
        //        central.connectPeripheral(peripheral, options: nil)
        //        println("Attempting to cnnect to peripheral")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Connected to a peripheral: %@", peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([uuid])
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("Failed to connect to peripheral %@", error)
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
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        NSLog("They wants to read me %@", characterstic)
        if request.characteristic.UUID == characterstic.UUID {
            if request.offset > characterstic.value.length {
                return peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            } else {
                request.value = characterstic.value.subdataWithRange(NSMakeRange(request.offset, characterstic.value.length - request.offset))
                
                peripheral.respondToRequest(request, withResult: CBATTError.Success)
            }
        }
    }
    
    // MARK: Peripheral Delegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services {
            peripheral.discoverCharacteristics([uuid], forService: service as CBService)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("Found us some characteristics")
        
        for characterstic in service.characteristics {
            peripheral.readValueForCharacteristic(characterstic as CBCharacteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            NSLog("Had an error while trying to read value on characteristic %@", error)
        } else {
            NSLog("Read value on characteristic %@", characterstic)
        }
    }
}
