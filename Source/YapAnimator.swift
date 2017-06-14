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

import Foundation

import QuartzCore

/// Your fast and friendly physics based animator.
public final class YapAnimator<T>: YapAnimatorCommonInterface where T: Animatable {

	/// Create a new `Yap Animator`
	///
	/// - Parameter initialValue: Set the initial value of the animator
	/// - Parameter willBegin: An optional closure that returns the 'model value' of your animated value. This is useful to synchronize the animator with a value that may get set outside of the scope of the animator.
	/// - Parameter completion: An optional closure that gets called when the animator comes to rest or is stopped otherwise. The `Bool` value passed into this closure will be `true` if the animator comes to rest at the `toValue` or `false` if the animator is stopped for any other reason.
	/// - Parameter action: A closure that is called at every frame of the animation. Use this closure to apply the animator's `current.value` to the value(s) that you wish to animate.
	public init(initialValue: T,
	            willBegin: ((YapAnimator) -> Void)? = nil,
	            completion: ((YapAnimator, _ finished: Bool) -> Void)? = nil,
	            action: ((YapAnimator) -> Void)?)
	{
		self.current = PhysicsState(value: initialValue, velocity: T.zero())
		self.toValue = initialValue
		self.willBegin = willBegin ?? { _ in }
		self.action = action ?? { _ in }
		self.completion = completion ?? { _ in }
		self.addToEngine()
	}

	/// Set the target value of the animator
	///
	/// - Parameter to: The target value of the animator
	/// - Parameter action: This closure gets called every frame of the animation just like the `action` that was defined in the animator's constructor but with a very important difference: **It is only called and retained as long as this function is not called again or the toValue does not change.**
	/// - Parameter animator: The associated `YapAnimator`
	/// - Parameter completion: This closure gets called when the animator comes to rest or is stopped otherwise. The `Bool` value passed into this closure will be `true` if the animator comes to rest at the `toValue` or `false` if the animator is stopped for any other reason. This is just like the `completion` in the constructor but with a very important difference: **It is only called and retained as long as this function is not called again or the toValue does not change.**
	/// - Parameter animator: The associated `YapAnimator`
	/// - Parameter finished: `true` if the animator comes to rest at the `toValue` or `false` if the animator is stopped for any other reason.
	public func animate(to: T, action: @escaping (_ animator: YapAnimator) -> Void = { _ in }, completion: @escaping (_ animator: YapAnimator, _ finished: Bool) -> Void = { _ in }) {
		// setting the toValue clears any extant targetedAction
		toValue = to
		targetedAction = action
		// will cancel any in-flight completion
		targetedCompletion(self, false)
		targetedCompletion = completion
	}

	// Animation Variables

	/// The target value of the animator
	public var toValue: T {
		didSet {
			if oldValue.components != toValue.components {
				targetedCompletion(self, false)
				targetedCompletion = { _ in }
				targetedAction = { _ in }
				setNeedsUpdate()
			}
		}
	}

	/// A value defining the bounciness of the animator. A value of `0` represents a critically dampened spring — one that moves as quickly to the target value without overshooting. A value of `1` represents an aesthetically pleasing bounce. This value can be set to values under or over this range.
	public var bounciness = 0.0 {
		didSet {
			if oldValue != bounciness {
				setNeedsUpdate()
			}
		}
	}

	/// A value defining the speed of the animator. A range from `0-1` defining aesthetically pleasing speeds has been selected by the Author, but feel free to play around with this. *Warning:* Very high speeds combined with high bounciness may 'blow up' the phsyics simulation.
	public var speed = 1.0 {
		didSet {
			if oldValue != speed {
				setNeedsUpdate()
			}
		}
	}

	/// Contains the in-flight value and velocity of the animator
	public var current: PhysicsState<T>

	fileprivate var accumulator = 0.0

	fileprivate var forces = T.zero()

	/// Applies an instantaneous push (using positive forces) or pull (using negative forces) to the animation
	///
	/// - Parameter force: The force to apply to the animator
	public func apply(force newForce: T) {

		forces = forces + newForce
		setNeedsUpdate()
	}

	/// Cancels the animator if it is in-flight
	public func stop() {

		if state == .began || state == .updated {
			stopExecution()
		}
	}

	// Actions

	fileprivate var willBegin: (YapAnimator) -> Void

	fileprivate var action: (YapAnimator) -> Void

	fileprivate var completion: (YapAnimator, _ finished: Bool) -> Void

	fileprivate var targetedAction: (YapAnimator) -> Void = { _ in }

	fileprivate var targetedCompletion: (YapAnimator, _ finished: Bool) -> Void = { _ in }

	fileprivate weak var observer: YapAnimatorObserver?


	fileprivate var needsUpdate = false

	fileprivate func setNeedsUpdate() {

		if !needsUpdate && state != .began {
			transition(to: .began)
		}

		needsUpdate = true
	}

	// State

	fileprivate var state = YapAnimatorState.possible {

		didSet {
			switch state {
			case .possible:
				break
			case .began:
				willBegin(self)
			case .updated:
				targetedAction(self)
				action(self)
			case .completed:
				targetedCompletion(self, true)
				targetedCompletion = { _ in }
				targetedAction = { _ in }

				completion(self, true)
			case .cancelled:
				targetedCompletion(self, false)
				targetedCompletion = { _ in }
				targetedAction = { _ in }

				completion(self, false)
			}
			observer?.didChangeState(animator: self)
		}
	}
}

// MARK: - Execution

extension YapAnimator {

	@discardableResult fileprivate func updateIfNeeded(dT: CFTimeInterval) -> Bool {

		if needsUpdate {
			needsUpdate = update(dT: dT)
			transition(to: .updated)
		}

		// Evaluate again to call completion if we're done
		if !needsUpdate {
			stopExecution()
		}

		return needsUpdate
	}

	@discardableResult private func update(dT: CFTimeInterval) -> Bool {

		// Sum forces
		let springForces = bouncy(offset: current.value - toValue, tension: computedTension(), friction: computedFriction())
		let otherForces = decay(forces: forces, resistance: 0)
		let combinedForces = { return springForces($0) + otherForces($0) }

		// Integrate
		let timestep = 1 / 240.0 // Fixed 1/240 s.
		accumulator += dT
		var integrated = current
		var prev = integrated

		while accumulator >= timestep {
			prev = integrated
			accumulator -= timestep
			euler(state: &integrated, acceleration: combinedForces, dT: timestep)
		}

		let per = accumulator / timestep
		current.value = T.composed(from: lerp(start: prev.value.components, end: integrated.value.components, percent: per))
		current.velocity = T.composed(from: lerp(start: prev.velocity.components, end: integrated.velocity.components, percent: per))

		// Reset forces
		forces = T.zero()
		
		let threshold = 0.001
		var isInMotion = false
		for ((value, velocity), toValue) in zip(zip(current.value.components, current.velocity.components), toValue.components) {
			isInMotion = abs(value - toValue) > threshold || abs(velocity) > threshold
			if isInMotion {
				break
			}
		}
		return isInMotion
	}

	fileprivate func stopExecution() {

		needsUpdate = false
		if needsUpdate || state != .updated {
			transition(to: .cancelled)
		} else {
			transition(to: .completed)
		}
	}

	fileprivate func transition(to state: YapAnimatorState) {
		switch state {
		case .possible:
			self.state = .possible
		case .began:
			self.state = .began
		case .updated:
			self.state = .updated
		case .cancelled:
			self.current = PhysicsState(value: toValue, velocity: T.zero())
			self.state = .updated
			self.state = .cancelled
			transition(to: .possible)
		case .completed:
			self.current = PhysicsState(value: toValue, velocity: T.zero())
			self.state = .updated
			self.state = .completed
			transition(to: .possible)
		}
	}
}

// MARK: - Integration & Helpers

fileprivate extension YapAnimator {

	typealias AccelerationFnType = (PhysicsState<T>) -> T

	func lerp(start: Double, end: Double, percent: Double) -> Double {
		return start + (end - start) * percent
	}

	func lerp(start: [Double], end: [Double], percent: Double) -> [Double] {
		return zip(start, end).flatMap { lerp(start: $0.0, end: $0.1, percent: percent) }
	}

	func criticalFriction() -> Double {
		return 2.0 * sqrt(computedTension())
	}

	func prettyFriction() -> Double {
		return criticalFriction() * 0.618
	}

	func computedTension() -> Double {
		return max(1, min(lerp(start: 14.0, end: 300.0, percent: speed), 3000.0))
	}

	func computedFriction() -> Double {
		return lerp(start: criticalFriction(), end: prettyFriction(), percent: min(bounciness, 3.0))
	}

	func addToEngine() {
		self.observer = Engine.sharedInstance
	}

	func bouncy(offset: T, tension: Double, friction: Double) -> AccelerationFnType {

		return { state in
			T.composed(from: zip(offset.components, state.velocity.components)
			.flatMap { $0.0 != 0.0 ? (-tension * $0.0) - (friction * $0.1) : 0.0 })
		}
	}

	func decay(forces: T, resistance: Double) -> AccelerationFnType {

		return { state in
			T.composed(from: zip(forces.components, state.velocity.components)
				.flatMap { $0.0 - $0.1 * resistance })
		}
	}

	func euler(state: inout PhysicsState<T>, acceleration: AccelerationFnType, dT: Double) {

		var values = [Double]()
		var velocities = [Double]()
		for ((value, velocity), acceleration) in zip(zip(state.value.components, state.velocity.components), acceleration(state).components) {
			let velocity = velocity + acceleration * dT
			velocities.append(velocity)
			values.append(value + velocity * dT)
		}
		state.value = T.composed(from: values)
		state.velocity = T.composed(from: velocities)
	}
}

// MARK: - Everything else

func +<T>(lhs: T, rhs: T) -> T where T: Animatable {
	return T.composed(from: zip(lhs.components, rhs.components).flatMap { $0.0 + $0.1 })
}

func -<T>(lhs: T, rhs: T) -> T where T: Animatable {
	return T.composed(from: zip(lhs.components, rhs.components).flatMap { $0.0 - $0.1 })
}

fileprivate enum YapAnimatorState {
	/// The `YapAnimator` is at rest
	case possible
	/// The `YapAnimator` has just requested that it be updated.
	case began
	/// The `YapAnimator` has updated and is still eligible for further updates
	case updated
	/// The `YapAnimator` has finished updating. The completion closure is called immediately with `true` after this state has been set. The `YapAnimator` will transition to `YapAnimatorState.Possible`.
	case completed
	/// The `YapAnimator` has stopped execution, but had outstanding updates to perform. The completion closure is called immediately with `false` after this state has been set. The `YapAnimator` will transition to `YapAnimatorState.Possible`.
	case cancelled
}

public struct PhysicsState<T> where T: Animatable {

	public var value: T

	public var velocity: T
}

fileprivate protocol YapAnimatorCommonInterface: class {

	var state: YapAnimatorState { get set }

	var observer: YapAnimatorObserver? { get set }

	@discardableResult func updateIfNeeded(dT: CFTimeInterval) -> Bool
}

fileprivate final class YapAnimatorBox {

	weak var value: YapAnimatorCommonInterface?

	init(value: YapAnimatorCommonInterface) {
		self.value = value
	}
}

fileprivate final class Engine: NSObject {

	static let sharedInstance = Engine()

	lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(Engine.step))

	var animators = [YapAnimatorBox]()

	override init() {
		super.init()

		displayLink.add(to: .current, forMode: .commonModes)
	}

	func add(animator: YapAnimatorCommonInterface) {

		displayLink.isPaused = false
		self.animators.append(YapAnimatorBox(value: animator))
	}

	func remove(animator: YapAnimatorCommonInterface) {

		for (idx, box) in animators.enumerated().reversed() {
			if animator === box.value {
				animators.remove(at: idx)
			}
		}
	}

	func step (with displayLink: CADisplayLink) {

		for (idx, box) in animators.enumerated().reversed() {
			if let animator = box.value {
				animator.updateIfNeeded(dT: displayLink.duration)
			} else {
				animators.remove(at: idx)
			}
		}

		if animators.isEmpty {
			displayLink.isPaused = true
		}
	}
}

extension Engine: YapAnimatorObserver {

	func didChangeState(animator: YapAnimatorCommonInterface) {

		switch animator.state {
		case .began:
			self.add(animator: animator)
		case .cancelled, .completed:
			self.remove(animator: animator)
		default:
			break
		}
	}
}

fileprivate protocol YapAnimatorObserver: class {

	func didChangeState(animator: YapAnimatorCommonInterface)
}
