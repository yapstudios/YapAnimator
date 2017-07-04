//
//  FirstViewController.swift
//  YapAnimatorExample
//
//  Created by Ollie Wagner on 6/12/17.
//  Copyright © 2017 Yap Studios. All rights reserved.
//

import UIKit
import YapAnimator

class FirstViewController: UIViewController {
    @IBOutlet weak var squircle: UIView!
    
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        
        squircle.backgroundColor = UIColor.black
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

    @IBAction func handle(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            squircle.animated.cornerRadius.animate(to: squircle.bounds.width / 2.0)
            squircle.animated.rotationZ.animate(to: .pi)
        } else if gesture.state == .changed {
            squircle.animated.position.instant(to: gesture.location(in: nil))
        } else if gesture.state == .ended {
            squircle.animated.position.animate(to: self.view.center)
            squircle.animated.cornerRadius.animate(to: 0)
            squircle.animated.rotationZ.animate(to: 0)
        }
    }
}

