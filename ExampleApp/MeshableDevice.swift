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
    var central = CBCentralManager()
    var peripheral = CBPeripheralManager()
    var services: [CBService] = []
    var delegate: MeshableDeviceDelegate?
    var discoveredPeripherals: [CBPeripheral] = []
    var whitelistedUUIDs: [CBUUID] = []
    
    // TODO: meshable json data needs to be sent in by init
    let jsonDictionary = [
        "services": [[
            "UUID": "CF4A6676-F75D-47F0-861C-767CFBE35466",
            "meshableType": "MeshableNodeService",
            "meshableDescription": "Encapsulating service to hold Mesh and Application characteristics",
            "characteristics": [[
                "UUID": "8D919FA1-5A2B-49AD-A617-F9BE246AAFAC",
                "meshableType": "MeshId",
                "meshableDescription": "ID of the mesh network this node belongs to, if any"
                ], [
                    "UUID": "27B041F2-2E81-44B9-A096-1A6ECB8A49B1",
                    "meshableType": "Id",
                    "meshableDescription": "128-bit id for this node in the network"
                ], [
                    "UUID": "2237D243-8105-4390-89CB-2C3B9986CD76",
                    "meshableType": "Pipe",
                    "meshableDescription": "Interface for reading/writing data to a node"
                ]]
            ]]
    ]
    
    override init() {
        if let jsonServices = jsonDictionary["services"] {
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
                self.services.append(service)
            }
        }
        
        super.init()
        
    }
    
    func addCharacteristic(uuid: CBUUID, withValue value: AnyObject) {

    }
    
    // MARK: Central Manager
    func startScanning(uuids: [CBUUID]?) {
        if let maybeUUIDs = uuids {
            self.whitelistedUUIDs = maybeUUIDs
        }
        
        central = CBCentralManager(delegate: self, queue: nil)
        peripheral = CBPeripheralManager(delegate: self, queue: nil)
        
        central.scanForPeripheralsWithServices(self.whitelistedUUIDs, options: nil)
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
    func startAdvertising() {
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey : services.map({ $0.UUID })])
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
