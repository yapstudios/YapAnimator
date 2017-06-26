Pod::Spec.new do |s|
  s.name         = "YapAnimator"
  s.version      = "1.1.0"
  s.summary      = "Yap Studios Animation Framework"
  s.homepage     = "http://yapstudios.com/"
  s.license      = "BSD"

	s.author       = {
		"Yap Studios" => "contact@yapstudios.com"
	}

	s.source       = {
		:git => 'https://github.com/yapstudios/YapAnimator.git',
		:tag => s.version
	}

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.source_files = 'Source/*.{swift}'
end
