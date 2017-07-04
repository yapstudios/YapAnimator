//
//  ViewController.swift
//  YapAnimatorMacExample
//
//  Created by Sam Gray on 6/29/17.
//  Copyright © 2017 Sam Gray. All rights reserved.
//

import Cocoa
import YapAnimator

class ViewController: NSViewController {
    @IBOutlet weak var squircle: NSView!
    var circle: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        let layer = CALayer()
        squircle.layer = layer
        layer.masksToBounds = false
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.backgroundColor = NSColor.black.cgColor
        layer.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func doAnimate(_ sender: NSButton) {
        if circle {
            squircle.animated.cornerRadius.animate(to: 0)
            squircle.animated.shadowColor.animate(to: NSColor.red)
            squircle.animated.shadowRadius.animate(to: 10)
            squircle.animated.shadowOpacity.animate(to: 1)
            squircle.animated.rotationZ.animate(to: 0)
        } else {
            squircle.animated.cornerRadius.animate(to: squircle.bounds.width / 2.0)
            squircle.animated.shadowColor.animate(to: NSColor.blue)
            squircle.animated.shadowRadius.animate(to: 2)
            squircle.animated.shadowOpacity.animate(to: 1)
            squircle.animated.rotationZ.animate(to: .pi)
        }
        
        circle = !circle
    }
}

