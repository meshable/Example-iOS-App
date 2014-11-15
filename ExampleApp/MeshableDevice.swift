//
//  MeshableDevice.swift
//  ExampleApp
//
//  Created by George Shank on 11/11/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import CoreBluetooth

enum MeshableDeviceBluetoothState: Int {
    case PoweredOff
    case PoweredOn
    case Resetting
    case Unauthorized
    case Unknown
    case Unsupported
}

protocol MeshableDeviceDelegate {
    func meshableDevice(device: MeshableDevice, didDiscoverPeripheral discoveredPeripheral: CBPeripheral)
    func meshableDevice(device: MeshableDevice, didConnectToPeripheral connectedPeripheral: CBPeripheral, withMeshId meshId: Int?)
    func bluetoothReady()
    func bluetoothNotReady(reason: String, bluetoothState: MeshableDeviceBluetoothState)
}

class MeshableDevice: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    var central: CBCentralManager?
    var peripheral: CBPeripheralManager?
    var services: [CBMutableService] = []
    var discoveredPeripherals: [CBPeripheral] = []
    var whitelistedUUIDs: [CBUUID] = []
    var state: MeshableDeviceBluetoothState = MeshableDeviceBluetoothState.Unknown
    var delegate: MeshableDeviceDelegate?
    
        
    init(jsonConfig: NSDictionary?, delegate: MeshableDeviceDelegate?) {
        super.init()
        self.delegate = delegate
        
        if let config = jsonConfig {
            services = parseMeshableConfig(config)
        }
        peripheral = CBPeripheralManager(delegate: self, queue: nil)
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    func parseMeshableConfig(config: NSDictionary) -> [CBMutableService] {
        var parsedServices: [CBMutableService] = []
        
        if let jsonServices = config["services"] as? NSArray {
            for jsonService in jsonServices {
                let serviceUUID = CBUUID(string: jsonService["UUID"] as String)
                let service = CBMutableService(type: serviceUUID, primary: true)
                var characteristics: [CBMutableCharacteristic] = []
                
                if let jsonCharacteristics = jsonService["characteristics"] as? [[String: String]] {
                    for jsonCharacteristic in jsonCharacteristics {
                        let characteristicUUID = CBUUID(string: jsonCharacteristic["UUID"])
                        let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: CBCharacteristicProperties.Read | CBCharacteristicProperties.Write | CBCharacteristicProperties.Indicate, value: nil, permissions: CBAttributePermissions.Readable | CBAttributePermissions.Writeable)
                        characteristics.append(characteristic)
                    }
                }
                
                service.characteristics = characteristics
                parsedServices.append(service)
            }
        }
        
        return parsedServices
    }
    
    func updateState(centralState: CBCentralManagerState?, peripheralState: CBPeripheralManagerState?) {
        var state: Int = MeshableDeviceBluetoothState.Unknown.rawValue
        
        if let maybeState = centralState {
            state = maybeState.rawValue
        } else if let maybeState = peripheralState {
            state = maybeState.rawValue
        }
        
        switch state {
        case CBCentralManagerState.PoweredOff.rawValue:
            fallthrough
        case CBPeripheralManagerState.PoweredOff.rawValue:
            if self.state != MeshableDeviceBluetoothState.PoweredOff {
                self.state = MeshableDeviceBluetoothState.PoweredOff
                delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is powered off", bluetoothState: MeshableDeviceBluetoothState.PoweredOff)
            }
            break
        case CBCentralManagerState.PoweredOn.rawValue:
            fallthrough
        case CBPeripheralManagerState.PoweredOn.rawValue:
            if self.state != MeshableDeviceBluetoothState.PoweredOn {
                self.state = MeshableDeviceBluetoothState.PoweredOn
                delegate?.bluetoothReady()
            }
            break
        case CBCentralManagerState.Resetting.rawValue:
            fallthrough
        case CBPeripheralManagerState.Resetting.rawValue:
            if self.state != MeshableDeviceBluetoothState.Resetting {
                self.state = MeshableDeviceBluetoothState.Resetting
                delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is resetting", bluetoothState: MeshableDeviceBluetoothState.Resetting)
            }
            break
        case CBCentralManagerState.Unauthorized.rawValue:
            fallthrough
        case CBPeripheralManagerState.Unauthorized.rawValue:
            if self.state != MeshableDeviceBluetoothState.Unauthorized {
                self.state = MeshableDeviceBluetoothState.Unauthorized
                delegate?.bluetoothNotReady("CoreBluetooth BLE state is unauthorized", bluetoothState: MeshableDeviceBluetoothState.Unauthorized)
            }
            break
        case CBCentralManagerState.Unknown.rawValue:
            fallthrough
        case CBPeripheralManagerState.Unknown.rawValue:
            if self.state != MeshableDeviceBluetoothState.Unknown {
                self.state = MeshableDeviceBluetoothState.Unknown
                delegate?.bluetoothNotReady("CoreBluetooth BLE state is unknown", bluetoothState: MeshableDeviceBluetoothState.Unknown)
            }
            break
        case CBCentralManagerState.Unsupported.rawValue:
            fallthrough
        case CBPeripheralManagerState.Unsupported.rawValue:
            if self.state != MeshableDeviceBluetoothState.Unsupported {
                self.state = MeshableDeviceBluetoothState.Unsupported
                delegate?.bluetoothNotReady("CoreBluetooth BLE hardware is unsupported on this platform", bluetoothState: MeshableDeviceBluetoothState.Unsupported)
            }
            break
            
        default:
            break
        }
    }
    
    func connectToPeripheral(peripheral: CBPeripheral, lookingForServiceUUIDs serviceUUIDs: [CBUUID], andCharacteristicUUIDs characteristicUUIDs: [CBUUID]?) {
        central?.connectPeripheral(peripheral, options: nil)
    }
    
    // MARK: Central Manager
    func startScanning(uuids: [CBUUID]?) {
        if let maybeUUIDs = uuids {
            self.whitelistedUUIDs = maybeUUIDs
        }
        
        if central == nil {
            central = CBCentralManager(delegate: self, queue: nil)
        }
        
        central!.scanForPeripheralsWithServices(self.whitelistedUUIDs, options: nil)
    }
    
    func stopScanning() {
        central!.stopScan()
    }
    
    // MARK: Central Manager Delegate
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        updateState(central.state, peripheralState: nil)
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        print("Central Manager will restore state")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Discovered a peripheral")
        
        //Seems we need to retain the discovered peripheral to successfully connect to it
        self.discoveredPeripherals.append(peripheral)
        
        //        central.connectPeripheral(peripheral, options: nil)
        //        println("Attempting to cnnect to peripheral")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Connected to a peripheral: %@", peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(self.whitelistedUUIDs)
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("Failed to connect to peripheral %@", error)
    }
    
    // MARK: Peripheral Manager
    func startAdvertising(uuids: [CBUUID]?, counter: Int?) {
        peripheral!.startAdvertising([CBAdvertisementDataServiceUUIDsKey : services.map({ $0.UUID })])
        
        //The first call to start advertising doesn't work, keep attempting until we are advertising
        var delta: Int64 = 1 * Int64(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, delta)
        var attemptCounter: Int = 3
        
        if let maybeCounter = counter {
            if maybeCounter <= 0 {
                return
            } else {
                attemptCounter = maybeCounter - 1
            }
        }
        
        dispatch_after(time, dispatch_get_main_queue(), {
            if !self.peripheral!.isAdvertising {
                self.startAdvertising(uuids, counter: attemptCounter)
            }
        });
    }
    
    func stopAdvertising() {
        peripheral!.stopAdvertising()
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
        updateState(nil, peripheralState: peripheral.state)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        if error != nil {
            print("Got an error")
        }
        
        NSLog("Service added: %@", service)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        var characteristic: CBCharacteristic?
        
        for service in services {
            for maybeCharacteristic in service.characteristics as [CBCharacteristic] {
                if maybeCharacteristic.UUID.UUIDString == request.characteristic.UUID.UUIDString {
                    characteristic = maybeCharacteristic
                    break
                }
            }
        }
        
        if let foundCharacteristic = characteristic {
            if request.offset > foundCharacteristic.value.length {
                return peripheral.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            } else {
                request.value = foundCharacteristic.value.subdataWithRange(NSMakeRange(request.offset, foundCharacteristic.value.length - request.offset))
                
                peripheral.respondToRequest(request, withResult: CBATTError.Success)
            }
        }
    }
    
    // MARK: Peripheral Delegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services {
            peripheral.discoverCharacteristics(whitelistedUUIDs, forService: service as CBService)
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
            NSLog("Read value on characteristic %@", characteristic)
        }
    }
}
