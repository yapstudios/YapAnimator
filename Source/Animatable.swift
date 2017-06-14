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

---

Authored by Ollie Wagner (ollie@yapstudios.com). Please feel free to
send an email to me if you have any questions.

*/

// Note: When adding `Animatable` conformance to types, be careful that the constructor does not clip or otherwise restrict values.

import Foundation
import UIKit

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
