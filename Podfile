source 'git@github.com:CocoaPods/Specs.git'
use_frameworks!	# needed to support Swift-based pods

workspace 'YapAnimatorExample'

target 'YapAnimatorExample' do
	platform :ios, '9.0'
	project 'YapAnimatorExample.xcodeproj'
# normal pods (read-only)
	pod 'YapAnimator', :path => './'
end

target 'YapAnimatorMacExample' do
	platform :osx, '10.12'
	project 'YapAnimatorMacExample/YapAnimatorMacExample.xcodeproj'
	pod 'YapAnimator', :path => './'
end
