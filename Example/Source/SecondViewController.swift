//
//  SecondViewController.swift
//  YapAnimatorExample
//
//  Created by Ollie Wagner on 6/12/17.
//  Copyright © 2017 Yap Studios. All rights reserved.
//

import UIKit
import YapAnimator

class SecondViewController: UIViewController {
    @IBOutlet weak var square: UIView!
    var frameAnimator: YapAnimator<CGRect>?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        
        setupFrameAnimator()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

    fileprivate func setupFrameAnimator() {
        guard frameAnimator == nil else {return}
        
        frameAnimator = YapAnimator(initialValue: square.frame, willBegin: { [unowned self] in
            return self.square.frame
            }, eachFrame: { [unowned self] (animator) in
                self.square.frame = animator.current.value
        })
        
        frameAnimator?.bounciness = 1.5
    }
    
    @IBAction func doAnimate(_ sender: UITapGestureRecognizer) {
        guard let frameAnimator = frameAnimator else {return}
        
        frameAnimator.animate(to: square.frame.insetBy(dx: -50, dy: -50), completion: { animator, wasInterrupted in
            if !wasInterrupted {
                // animate back to the original value
                animator.animate(to: animator.current.value.insetBy(dx: 50, dy: 50))
            }
        })
    }
}

