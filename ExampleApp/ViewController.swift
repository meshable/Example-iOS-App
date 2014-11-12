//
//  ViewController.swift
//  ExampleApp
//
//  Created by George Shank on 11/4/14.
//  Copyright (c) 2014 Meshable. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var messageInputField: UITextField!
    @IBOutlet var messageDisplay: UILabel!
    @IBOutlet var connectionStatus: UILabel!
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

