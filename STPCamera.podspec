Pod::Spec.new do |s|

  s.name         = "STPCamera"
  s.version      = "0.2.0"
  s.summary      = "The camera."
  s.homepage     = "https://github.com/Taktstck/STPCamera"
  #s.screenshots	 = ""
  s.license      = { :type => "BSD" }
  s.author       = { "1_am_a_geek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1_am_a_geek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/Taktstck/STPCamera.git", :tag => "0.2.0" }
  s.source_files  = ["STPCamera/STPCameraMnager.*","STPCamera/STPCameraView.*"]
  s.public_header_files = "STPCamera/**/*.h"
  s.frameworks	= ["ImageIO", "AVFoundation", "CoreMotion", "CoreLocation"]
  s.dependency "pop", "~> 1.0"

end
