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

import QuartzCore

/// Your fast and friendly physics based animator.
public final class YapAnimator<T>: YapAnimatorCommonInterface where T: Animatable {

	/// Create a new `Yap Animator`
	///
	/// - Parameter initialValue: Set the initial value of the animator
	/// - Parameter willBegin: An optional closure where you return the 'model value' of the animated value. This is useful to synchronize the animator with a value that may get set outside of the scope of the animator.
	/// - Parameter eachFrame: A closure that is called at every frame of the animation. Use this closure to apply the animator's `current.value` to the value(s) that you wish to animate.
	public init(initialValue: T,
	            willBegin: (() -> T)? = nil,
	            eachFrame: ((YapAnimator) -> Void)?)
	{
		self.current = PhysicsState(value: initialValue, velocity: T.zero())
		self.toValue = initialValue
		self.eachFrame = eachFrame ?? { _ in }
		self.addToEngine()
	}

	/// Set the target value of the animator
	///
	/// - Parameter to: The target value of the animator
	/// - Parameter animator: The associated `YapAnimator`
	/// - Parameter completion: This closure gets called when the animator comes to rest or is stopped otherwise. The `Bool` value passed into this closure will be `true` if the animator comes to rest at the `toValue` or `false` if the animator is stopped or a new `toValue` is set by calling this method again before the previous animation finishes.
	/// - Parameter animator: The associated `YapAnimator`
	/// - Parameter wasInterrupted: `false` if the animator comes to rest at the `toValue` or `true` if the animator is stopped for any other reason.
	public func animate(to: T, completion: @escaping (_ animator: YapAnimator, _ wasInterrupted: Bool) -> Void = { _, _ in }) {

		toValue = to
		fulfillCompletion(success: false, newCompletion: completion)
	}

	public func instant(to: T) {

		fulfillCompletion(success: false)
		needsUpdate = false
		toValue = to
		updateInstant()
	}

	// Animation Variables

	/// The target value of the animator
	public private(set) var toValue: T {
		didSet {
			setNeedsUpdate()
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

	fileprivate var willBegin: (() -> T)?

	fileprivate var eachFrame: (YapAnimator) -> Void

	fileprivate var completion: (YapAnimator, _ finished: Bool) -> Void = { _, _ in }

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
				if let willBegin = willBegin {
					self.current.value = willBegin()
					self.current.velocity = T.zero()
				}
			case .updated:
				eachFrame(self)
			case .completed:
				fulfillCompletion(success: true)
			case .cancelled:
				fulfillCompletion(success: false)
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
			// Unlike the `completion`, `eachFrame` can be called sync in the flow as it will
			// update `needsUpdate` before evaluating to stop execution. This is an important
			// flow as you might change something in the animator that requires an update.
			transition(to: .updated)
		}

		// Evaluate again to call completion if we're done
		if !needsUpdate {
			stopExecution()
		}

		return needsUpdate
	}

	fileprivate func updateInstant() {
		current = PhysicsState(value: toValue, velocity: T.zero())
	}

	@discardableResult private func update(dT: CFTimeInterval) -> Bool {

		// Sum forces
		let springForces = bouncy(offset: current.value - toValue, tension: computedTension(), friction: computedFriction())
		let otherForces = decay(forces: forces, resistance: 0, dT: dT)
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

	func fulfillCompletion(success: Bool, newCompletion: @escaping (_ animator: YapAnimator, _ wasInterrupted: Bool) -> Void = { _, _ in }) {

		let completionCopy = self.completion
		completion = newCompletion
		DispatchQueue.main.async {
			completionCopy(self, success ? false : true)
		}
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

	func decay(forces: T, resistance: Double, dT: CFTimeInterval) -> AccelerationFnType {

		return { state in
			T.composed(from: zip(forces.components, state.velocity.components)
				.flatMap { ($0.0 / dT) - $0.1 * resistance })
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

fileprivate final class DisplayLink: NSObject {

	#if os(macOS)

	var displayLink: CVDisplayLink?

	var lastOutputType: Int64 = 0

	#elseif os(iOS) || os(tvOS)

	var displayLink: CADisplayLink?

	#endif

	var paused: Bool = true {
		didSet {
			if paused {
				#if os(macOS)
					if let displayLink = displayLink {
						CVDisplayLinkStop(displayLink)
					}
				#elseif os(iOS) || os(tvOS)
					displayLink?.isPaused = true
				#endif
			} else {
				#if os(macOS)
					if let displayLink = displayLink {
						CVDisplayLinkStart(displayLink)
					}
				#elseif os(iOS) || os(tvOS)
					displayLink?.isPaused = false
				#endif
			}
		}
	}

	var duration: CFTimeInterval = 0

	var step: (DisplayLink) -> Void

	init(step: @escaping (DisplayLink) -> Void) {

		self.step = step
		super.init()

		#if os(macOS)

			CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
			if let displayLink = displayLink {
				CVDisplayLinkSetOutputHandler(displayLink, step(with:now:outputTime:flagsIn:flagsOut:))
			}

		#elseif os(iOS) || os(tvOS)

			displayLink = CADisplayLink(target: self, selector: #selector(step(with:)))
			displayLink?.add(to: .current, forMode: .commonModes)

		#endif
	}

	#if os(macOS)

	@objc func step (with displayLink: CVDisplayLink, now: UnsafePointer<CVTimeStamp>, outputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn {

		duration = CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLink)
		DispatchQueue.main.async {
			self.step(self)
		}
		return kCVReturnSuccess
	}

	#elseif os(iOS) || os(tvOS)

	@objc func step (with displayLink: CADisplayLink) {

		duration = displayLink.duration
		self.step(self)
	}

	#endif
}

fileprivate final class Engine: NSObject {

	static let sharedInstance = Engine()

	lazy var displayLink: DisplayLink = DisplayLink { [weak self] displayLink in
		self?.step(with: displayLink)
	}

	var animators = [YapAnimatorBox]()

	func add(animator: YapAnimatorCommonInterface) {

		displayLink.paused = false
		self.animators.append(YapAnimatorBox(value: animator))
	}

	func remove(animator: YapAnimatorCommonInterface) {

		for (idx, box) in animators.enumerated().reversed() {
			if animator === box.value {
				animators.remove(at: idx)
			}
		}
	}

	@objc func step (with displayLink: DisplayLink) {

		for (idx, box) in animators.enumerated().reversed() {
			if let animator = box.value {
				animator.updateIfNeeded(dT: displayLink.duration)
			} else {
				animators.remove(at: idx)
			}
		}

		if animators.isEmpty {
			displayLink.paused = true
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
