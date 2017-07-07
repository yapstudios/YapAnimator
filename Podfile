use_frameworks!	# needed to support Swift-based pods

def shared
	# normal pods (read-only)
	pod 'YapAnimator', :path => './'
end

target 'YapAnimatorExample-iOS' do
	platform :ios, '9.0'
	shared
end

target 'YapAnimatorExample-tvOS' do
	platform :tvos, '10.0'
	shared
end

target 'YapAnimatorExample-macOS' do
	platform :osx, '10.9'
	shared
end
