Pod::Spec.new do |s|

  s.name         = "STPCamera"
  s.version      = "0.1.0"
  s.summary      = "The camera."
  s.homepage     = "https://github.com/1amageek/STPCamera"
  #s.screenshots	 = ""
  s.license      = { :type => "BSD" }
  s.author       = { "1_am_a_geek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1_am_a_geek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/1amageek/STPCamera.git", :tag => "0.1.0" }
  s.source_files  = ["STPCamera/**/*.{h,m}"]
  s.exclude_files = ["STPCamera/AppDelegate.*", "STPCamera/main.m"]
  s.public_header_files = "STPCamera/**/*.h"
  #s.frameworks	= ["ImageIO", "AVFoundation", "CoreMotion", "CoreLocation"]
  s.dependency "pop", "~> 1.0"

end
