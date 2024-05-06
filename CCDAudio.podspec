Pod::Spec.new do |spec|

  spec.name         = "CCDAudio"
  spec.version      = "0.0.1"
  spec.summary      = "Audio:音频工具整理记录"

  spec.description  = <<-DESC
			音频工具整理记录,包括录音、播放等。	
                   DESC

  spec.homepage     = "https://github.com/zhu410289616/Audio"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  #spec.license      = "MIT (example)"
  spec.license      = { :type => "MIT", :file => "LICENSE" }


  spec.author             = { "zhu410289616" => "zhu410289616@163.com" }
  # Or just: spec.author    = "zhu410289616"
  # spec.authors            = { "zhu410289616" => "zhu410289616@163.com" }
  # spec.social_media_url   = "https://twitter.com/zhu410289616"


  # spec.platform     = :ios
  spec.platform     = :ios, "9.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  spec.source       = { :git => "https://github.com/zhu410289616/Cicada.git", :tag => "#{spec.version}" }

  spec.default_subspec = "Core", "UIKit"

  spec.subspec "Core" do |cs|
    cs.source_files = "Pod/Core/**/*.{h,m,mm}"
    cs.vendored_libraries = 'Pod/Core/Frameworks/**/*.a'
    cs.dependency "libextobjc/EXTScope"
  end
  
  spec.subspec "UIKit" do |cs|
    cs.source_files = "Pod/UIKit/**/*.{h,m,mm}"
    cs.dependency "MarqueeLabel-ObjC"
  end
  
#  spec.subspec "Controller" do |cs|
#    cs.source_files = "Cicada/Audio/**/*"
#    cs.vendored_libraries = 'Cicada/Audio/Frameworks/**/*.a'
#    ### for VC
#    cs.dependency "CicadaFoundation"
#    cs.dependency "CicadaHttp"
#    cs.dependency "CicadaIoC"
#    cs.dependency "CicadaRouter"
#  end
  
end
