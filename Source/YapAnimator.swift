//
//  YapAnimator.swift
//  OpenSourceYapMotion
//
//  Created by Ollie Wagner
//  Copyright © 2017 Yap Studios. All rights reserved.
//

import Foundation

import QuartzCore

public enum YapAnimatorState {
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

/// Conforming Types are animatable using YapAnimator
public protocol Animatable {

	/// Conforming Types should return an Array of `Doubles` representing the type
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

func +<T>(lhs: T, rhs: T) -> T where T: Animatable {
	return T.composed(from: zip(lhs.components, rhs.components).flatMap { $0.0 + $0.1 })
}

func -<T>(lhs: T, rhs: T) -> T where T: Animatable {
	return T.composed(from: zip(lhs.components, rhs.components).flatMap { $0.0 - $0.1 })
}

public struct PhysicsState<T> where T: Animatable {

	public var value: T

	public var velocity: T
}

public final class YapAnimator<T>: YapAnimatorCommonInterface where T: Animatable {

	// Animation Variables

	public var toValue: T {
		didSet {
			if oldValue.components != toValue.components {
				setNeedsUpdate()
			}
		}
	}

	public var bounciness = 0.0 {
		didSet {
			if oldValue != bounciness {
				setNeedsUpdate()
			}
		}
	}

	public var speed = 1.0 {
		didSet {
			if oldValue != speed {
				setNeedsUpdate()
			}
		}
	}

	public var current: PhysicsState<T>

	fileprivate var accumulator = 0.0

	fileprivate var forces = T.zero()

	public func apply(force newForce: T) {

		forces = forces + newForce
		setNeedsUpdate()
	}

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

	// Actions

	fileprivate var willBegin: (YapAnimator) -> Void

	fileprivate var action: (YapAnimator) -> Void

	public var completion: (YapAnimator, _ finished: Bool) -> Void

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
				action(self)
			case .completed:
				completion(self, true)
			case .cancelled:
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

	func stopExecution() {

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
		return criticalFriction() * 0.85
	}

	func computedTension() -> Double {
		return max(1, min(lerp(start: 14.0, end: 600.0, percent: speed), 3000.0))
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
