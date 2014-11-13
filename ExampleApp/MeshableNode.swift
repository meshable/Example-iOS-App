//
//  MeshableNode.swift
//  ExampleApp
//
//  Created by George Shank on 11/11/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import CoreBluetooth

struct MeshableConstants {
    static let MESHABLE_UUID = CBUUID(string: "CF4A6676-F75D-47F0-861C-767CFBE35466")
    static let MESHABLE_CONNECTED_STATUS_UUID = CBUUID(string: "C60093FF-6567-4EFF-AC63-844CBEBCCCBC")
    static let MESHABLE_CHARACTERISTIC_MESH_ID_UUID = CBUUID(string: "8D919FA1-5A2B-49AD-A617-F9BE246AAFAC")
    static let MESHABLE_CHARACTERISTIC_ID_UUID = CBUUID(string: "27B041F2-2E81-44B9-A096-1A6ECB8A49B1")
    static let MESHABLE_CHARACTERISTIC_PIPE_UUID = CBUUID(string: "2237D243-8105-4390-89CB-2C3B9986CD76")
}

class MeshableNode: MeshableDeviceDelegate {
    var readyToStartDiscovery = false
    var currentlyDiscovering = false
    var delegate: MeshableNodeDelegate
    var device = MeshableDevice(jsonConfig: nil, delegate: nil)
    var meshId: Int?
    var connectedPeripherals: [CBPeripheral] = []
    
    //TODO: Temporary
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

    
    init(delegate: MeshableNodeDelegate) {
        self.delegate = delegate
        device = MeshableDevice(jsonConfig: jsonDictionary, delegate: self)
    }
    
    func startDiscovery() {
        var scanUUIDs: [CBUUID] = []
        var advertiseUUIDs: [CBUUID] = [MeshableConstants.MESHABLE_UUID]
        
        
        if meshId != nil {
            //Only look for meshed nodes
            scanUUIDs.append(MeshableConstants.MESHABLE_CONNECTED_STATUS_UUID)
            //Advertise that we are a meshed node
            advertiseUUIDs.append(MeshableConstants.MESHABLE_CONNECTED_STATUS_UUID)
        } else {
            //Just scan for all meshable nodes
            scanUUIDs.append(MeshableConstants.MESHABLE_UUID)
        }
        
        device.startScanning(scanUUIDs)
        device.startAdvertising(advertiseUUIDs)
    }
    
    func stopDiscovery() {
        //Stop looking for nodes to connect to and stop advertising
        //This breaks existing connections with other nodes
        //Communicates tear down to the network
        device.stopScanning()
        device.stopAdvertising()
    }
    
    //Not in love with this honestly
    func stopDiscoveryWhileMaintainingConnections() {
        //Stop advertising/scanning but maintain existing mesh
    }
    
    func publishValue(value: String, toKey key: String) {
        //Set value in internal state and then publish to all connected nodes
    }
    
    func subscribeToKey(key: String) {
        //Listen to updates from a particular key
    }
    
    func generateMeshId() -> Int {
        return 3
    }
    
    //MARK: MeshableDeviceDelegate functions
    
    func bluetoothReady() {
        readyToStartDiscovery = true
    }
    
    func bluetoothNotReady(reason: String, bluetoothState: MeshableDeviceBluetoothState) {
        readyToStartDiscovery = false
        delegate.meshableNode(self, unableToStartDiscovery: reason)
    }
    
    func meshableDevice(device: MeshableDevice, didConnectToPeripheral connectedPeripheral: CBPeripheral, withMeshId meshId: Int?) {
        if meshId != nil {
            self.meshId = meshId
        }
        connectedPeripherals.append(connectedPeripheral)
    }
    
    func meshableDevice(device: MeshableDevice, didDiscoverPeripheral discoveredPeripheral: CBPeripheral) {
        device.connectToPeripheral(discoveredPeripheral, lookingForServiceUUIDs: [MeshableConstants.MESHABLE_UUID], andCharacteristicUUIDs: [MeshableConstants.MESHABLE_CHARACTERISTIC_MESH_ID_UUID, MeshableConstants.MESHABLE_CHARACTERISTIC_ID_UUID, MeshableConstants.MESHABLE_CHARACTERISTIC_PIPE_UUID])
    }
    
}

protocol MeshableNodeDelegate {
    //notification of connection to a node
    func meshableNode(node: MeshableNode, discoveredAndConnectedToNode discoveredNode: MeshableNode)
    
    //notification for when a node connects to this node
    func meshableNode(node: MeshableNode, connectedToFromExternalNode externalNode: MeshableNode)
    
        //Be notified up updates to store
    func meshableNode(node: MeshableNode, didReceiveUpdatedValue value: String, forKey key: String)
    
    //Be notified when node is online
    func meshableNodeDidStartDiscovery(node: MeshableNode)
    
    //Be notified when node goes offline
    func meshableNode(node: MeshableNode, unableToStartDiscovery reason: String)
}

