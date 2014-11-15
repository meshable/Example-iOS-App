//
//  ViewController.swift
//  ExampleApp
//
//  Created by George Shank on 11/4/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, MeshableNodeDelegate {
    @IBOutlet var messageInputField: UITextField!
    @IBOutlet var messageDisplay: UILabel!
    @IBOutlet var connectionStatus: UILabel!
    var node: MeshableNode?
    
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
        
        messageDisplay.text = message
        var messageBuffer = message.dataUsingEncoding(NSUTF8StringEncoding)
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        sendMessage(textField.text)
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        node = MeshableNode(delegate: self)
        node!.startDiscovery()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Meshable Node Delegate
    //notification of connection to a node
    func meshableNode(node: MeshableNode, discoveredAndConnectedToNode discoveredNode: MeshableNode) {
        println("Discovered and connected to a node")
    }
    
    //notification for when a node connects to this node
    func meshableNode(node: MeshableNode, connectedToFromExternalNode externalNode: MeshableNode) {
        println("Node was connected to by an external node")
    }
    
    //Be notified up updates to store
    func meshableNode(node: MeshableNode, didReceiveUpdatedValue value: String, forKey key: String) {
        println("Value for key %@ updated with %@", key, value)
    }
    
    //Be notified when node starts discovery
    func meshableNodeDidStartDiscovery(node: MeshableNode) {
        println("Now scanning for nodes")
    }
    
    //Be notified when node can not start discovery
    func meshableNode(node: MeshableNode, unableToStartDiscovery reason: String) {
        NSLog("Node could not start discovery: %@", reason)
    }
    
}

