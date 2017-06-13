/*
Copyright © 2017 Yap Studios LLC (http://yapstudios.com)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Authored by Ollie Wagner (ollie@yapstudios.com). Please feel free to send an email to me if you have any questions.
*/

import Foundation
import UIKit

extension UIView {

	/// Returns an phsyics-based implicitly animatable version of the layer
	public var animated: YapAnimatedLayer {
		return self.layer.animatedLayer
	}
}

extension CALayer {

	/// Returns an phsyics-based implicitly animatable version of the layer
	public var animatedLayer: YapAnimatedLayer {
		get {
			if let animatedLayer = self.value(forKey: "YapAnimatedLayer") {
				return animatedLayer as! YapAnimatedLayer
			} else {
				let animatedLayer = YapAnimatedLayer(delegate: self)
				self.setValue(animatedLayer, forKey: "YapAnimatedLayer")
				return animatedLayer
			}
		}
		set {
			self.setValue(newValue, forKey: "YapAnimatedLayer")
		}
	}
}

/// A physics-based implicitly animatable layer
public class YapAnimatedLayer {

	private weak var delegate: CALayer?

	init(delegate: CALayer) {

		self.delegate = delegate
	}

	var speed = 1.0

	var bounciness = 0.0

	// MARK: - Animatable Properties

	public lazy var bounds: YapAnimator<CGRect> = YapAnimator(initialValue: self.delegate!.bounds, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.bounds ?? CGRect.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.bounds = animator.current.value
	})

	public lazy var position: YapAnimator<CGPoint> = YapAnimator(initialValue: self.delegate!.position, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.position ?? CGPoint.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.position = animator.current.value
	})

	public lazy var zPosition: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.zPosition, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.zPosition ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.zPosition = animator.current.value
	})

	public lazy var anchorPoint: YapAnimator<CGPoint> = YapAnimator(initialValue: self.delegate!.anchorPoint, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.anchorPoint ?? CGPoint.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.anchorPoint = animator.current.value
	})

	public lazy var anchorPointZ: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.anchorPointZ, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.anchorPointZ ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.anchorPointZ = animator.current.value
	})

	public lazy var transform: YapAnimator<CATransform3D> = YapAnimator(initialValue: self.delegate!.transform, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.transform ?? CATransform3DIdentity
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.transform = animator.current.value
	})

	public lazy var translation: YapAnimator<CGPoint> = YapAnimator(initialValue: CGPoint.zero, willBegin: { [unowned self] animator in
		animator.current.value = (self.delegate?.value(forKeyPath: "transform.translation")! as AnyObject).cgPointValue ?? CGPoint.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.setValue(animator.current.value, forKeyPath: "transform.translation")
	})

	public lazy var rotationZ: YapAnimator<CGFloat> = YapAnimator(initialValue: 0, willBegin: { [unowned self] animator in
		animator.current.value = CGFloat((self.delegate?.value(forKeyPath: "transform.rotation")! as AnyObject).floatValue ?? 0)
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.setValue(animator.current.value, forKeyPath: "transform.rotation")
	})

	public lazy var scale: YapAnimator<CGFloat> = YapAnimator(initialValue: 0, willBegin: { [unowned self] animator in
		animator.current.value = CGFloat((self.delegate?.value(forKeyPath: "transform.scale")! as AnyObject).floatValue ?? 1)
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.setValue(animator.current.value, forKeyPath: "transform.scale")
	})

	public lazy var frame: YapAnimator<CGRect> = YapAnimator(initialValue: self.delegate!.frame, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.frame ?? CGRect.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.frame = animator.current.value
	})

	public lazy var sublayerTransform: YapAnimator<CATransform3D> = YapAnimator(initialValue: self.delegate!.sublayerTransform, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.sublayerTransform ?? CATransform3DIdentity
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.sublayerTransform = animator.current.value
	})

	public lazy var contentsRect: YapAnimator<CGRect> = YapAnimator(initialValue: self.delegate!.contentsRect, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.contentsRect ?? CGRect.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.contentsRect = animator.current.value
	})

	public lazy var contentsScale: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.contentsScale, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.contentsScale ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.contentsScale = animator.current.value
	})

	public lazy var contentsCenter: YapAnimator<CGRect> = YapAnimator(initialValue: self.delegate!.contentsCenter, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.contentsCenter ?? CGRect.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.contentsCenter = animator.current.value
	})

	public lazy var minificationFilterBias: YapAnimator<Float> = YapAnimator(initialValue: self.delegate!.minificationFilterBias, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.minificationFilterBias ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.minificationFilterBias = animator.current.value
	})

	public lazy var backgroundColor: YapAnimator<UIColor> = YapAnimator(initialValue: self.unwrappedColorOrDefault(from: self.delegate?.backgroundColor), willBegin: { [unowned self] animator in
		animator.current.value = self.unwrappedColorOrDefault(from: self.delegate?.backgroundColor)
	}, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.backgroundColor = animator.current.value.cgColor
	})

	public lazy var cornerRadius: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.cornerRadius, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.cornerRadius ?? 0
  }, action: { [unowned self] animator in
		guard self.self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.cornerRadius = animator.current.value
	})

	public lazy var borderWidth: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.borderWidth, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.borderWidth ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.borderWidth = animator.current.value
	})

	public lazy var borderColor: YapAnimator<UIColor> = YapAnimator(initialValue: self.unwrappedColorOrDefault(from: self.delegate?.borderColor), willBegin: { [unowned self] animator in
		animator.current.value = self.unwrappedColorOrDefault(from: self.delegate?.borderColor)
	}, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.borderColor = animator.current.value.cgColor
	})

	public lazy var opacity: YapAnimator<Float> = YapAnimator(initialValue: self.delegate!.opacity, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.opacity ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.opacity = animator.current.value
	})

	public lazy var rasterizationScale: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.rasterizationScale, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.rasterizationScale ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.rasterizationScale = animator.current.value
	})

	public lazy var shadowColor: YapAnimator<UIColor> = YapAnimator(initialValue: self.unwrappedColorOrDefault(from: self.delegate?.shadowColor), willBegin: { [unowned self] animator in
		animator.current.value = self.unwrappedColorOrDefault(from: self.delegate?.shadowColor)
	}, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.shadowColor = animator.current.value.cgColor
	})

	public lazy var shadowOpacity: YapAnimator<Float> = YapAnimator(initialValue: self.delegate!.shadowOpacity, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.shadowOpacity ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.shadowOpacity = animator.current.value
	})

	public lazy var shadowOffset: YapAnimator<CGSize> = YapAnimator(initialValue: self.delegate!.shadowOffset, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.shadowOffset ?? CGSize.zero
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.shadowOffset = animator.current.value
	})

	public lazy var shadowRadius: YapAnimator<CGFloat> = YapAnimator(initialValue: self.delegate!.shadowRadius, willBegin: { [unowned self] animator in
		animator.current.value = self.delegate?.shadowRadius ?? 0
  }, action: { [unowned self] animator in
		guard self.verify(value: animator.current.value) else { return }
		animator.speed = self.speed
		animator.bounciness = self.bounciness
		self.delegate?.shadowRadius = animator.current.value
	})

	// MARK: - Helpers

	private func verify(value: Animatable) -> Bool {
		var isValid = true
		for component in value.components {
			isValid = isValid && component.isFinite
			if !isValid {
				break
			}
		}
		return isValid
	}

	private func unwrappedColorOrDefault(from color: CGColor?) -> UIColor {
		if let color = color {
			return UIColor(cgColor: color)
		}
		return UIColor.clear
	}
}
