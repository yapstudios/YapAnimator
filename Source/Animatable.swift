/*
Copyright © 2017 Yap Studios LLC (http://yapstudios.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

Authored by Ollie Wagner (ollie@yapstudios.com). Please feel free to
send an email to me if you have any questions.

*/

import Foundation

import UIKit

/// Conforming Types are animatable using `YapAnimator`
public protocol Animatable {

	/// Conforming Types should return an Array of `Doubles` representing the Type
	var components: [Double] { get }

	/// Create an instance initialized with `elements`.
	static func composed(from elements: [Double]) -> Self

	static func zero() -> Self

	static var count: Int { get }
}

extension Animatable {

	public static func zero() -> Self {
		return self.composed(from: Array<Double>(repeating: 0, count: self.count))
	}
}

// MARK: - Examples of `Animatable` conformance for some common types

extension Float: Animatable {

  public static func composed(from elements: [Double]) -> Float {
    return Float(elements[0])
  }

  public var components: [Double] {
    return [Double(self)]
  }

	public static var count: Int {
		return 1
	}
}

extension Double: Animatable {

  public static func composed(from elements: [Double]) -> Double {
    return elements[0]
  }

  public var components: [Double] {
    return [self]
  }

	public static var count: Int {
		return 1
	}
}

extension CGFloat: Animatable {

  public static func composed(from elements: [Double]) -> CGFloat {
    return CGFloat(elements[0])
  }

  public var components: [Double] {
    return [Double(self)]
  }

	public static var count: Int {
		return 1
	}
}

extension CGPoint: Animatable {

  public static func composed(from elements: [Double]) -> CGPoint {
    return CGPoint(x: elements[0], y: elements[1])
  }

  public var components: [Double] {
    return [Double(x), Double(y)]
  }

	public static var count: Int {
		return 2
	}
}

extension CGSize: Animatable {

  public static func composed(from elements: [Double]) -> CGSize {
    return CGSize(width: elements[0], height: elements[1])
  }

  public var components: [Double] {
    return [Double(width), Double(height)]
  }

	public static var count: Int {
		return 2
	}
}

extension CGRect: Animatable {

  public static func composed(from elements: [Double]) -> CGRect {
    return CGRect(x: elements[0], y: elements[1], width: elements[2], height: elements[3])
  }

  public var components: [Double] {
    return [Double(origin.x), Double(origin.y), Double(size.width), Double(size.height)]
  }

	public static var count: Int {
		return 4
	}
}

extension CGVector: Animatable {

	public static func composed(from elements: [Double]) -> CGVector {
		return CGVector(dx: elements[0], dy: elements[1])
	}

	public var components: [Double] {
		return [Double(dx), Double(dy)]
	}

	public static var count: Int {
		return 2
	}
}

extension UIColor: Animatable {

  public static func composed(from elements: [Double]) -> Self {
		let color = UIColor(red: CGFloat(elements[0]), green: CGFloat(elements[1]), blue: CGFloat(elements[2]), alpha: CGFloat(elements[3]))
    return self.init(cgColor: color.cgColor)
  }

  public var components: [Double] {
    var r = CGFloat(0.0)
    var g = CGFloat(0.0)
    var b = CGFloat(0.0)
    var a = CGFloat(0.0)

    getRed(&r, green: &g, blue: &b, alpha: &a)
    return [Double(r), Double(g), Double(b), Double(a)]
  }

	public static func zero() -> Self {
		return self.composed(from: Array<Double>(repeating: 0, count: count))
	}

	public static var count: Int {
		return 4
	}
}

extension CATransform3D: Animatable {

  public static func composed(from elements: [Double]) -> CATransform3D {
    return CATransform3D(
      m11: CGFloat(elements[0]), m12: CGFloat(elements[1]), m13: CGFloat(elements[2]), m14: CGFloat(elements[3]),
      m21: CGFloat(elements[4]), m22: CGFloat(elements[5]), m23: CGFloat(elements[6]), m24: CGFloat(elements[7]),
      m31: CGFloat(elements[8]), m32: CGFloat(elements[9]), m33: CGFloat(elements[10]), m34: CGFloat(elements[11]),
      m41: CGFloat(elements[12]), m42: CGFloat(elements[13]), m43: CGFloat(elements[14]), m44: CGFloat(elements[15])
    )
  }

  public var components: [Double] {
    return [
      Double(m11), Double(m12), Double(m13), Double(m14),
      Double(m21), Double(m22), Double(m23), Double(m24),
      Double(m31), Double(m32), Double(m33), Double(m34),
      Double(m41), Double(m42), Double(m43), Double(m44)
    ]
  }

	public static var count: Int {
		return 16
	}
}
