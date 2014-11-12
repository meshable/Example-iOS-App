//
//  MeshableNode.swift
//  ExampleApp
//
//  Created by George Shank on 11/11/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import CoreBluetooth

class MeshableNode: MeshableDevice {
    var applicationUUID: CBUUID?
    
    init (appUUID: CBUUID?) {
        if appUUID != nil {
            applicationUUID = appUUID
        }
        
        super.init()
    }
    
    func startDiscovery() {
        //Start looking for nodes to connect to and start advertising
    }
    
    func stopDiscovery() {
        //Stop looking for nodes to connect to and stop advertising
        //This breaks existing connections with other nodes
        //Communicates tear down to the network
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
    
}

protocol MeshableNodeDelegate {
    //notification of connection to a node
    func meshableNode(node: MeshableNode, discoveredAndConnectedToNode discoveredNode: MeshableNode)
    
    //notification for when a node connects to this node
    func meshableNode(node: MeshableNode, connectedToFromExternalNode externalNode: MeshableNode)
    
    //potential error notification when trying to connect to a node
    func meshableNode(node: MeshableNode, discoveredButCouldNotConnectToNode discoveredNode: MeshableNode)
    
    //Be notified up updates to store
    func meshableNode(node: MeshableNode, didReceiveUpdatedValue value: String, forKey key: String)
}

