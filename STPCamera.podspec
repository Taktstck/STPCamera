Pod::Spec.new do |s|

  s.name         = "STPCamera"
  s.version      = "0.1.0"
  s.summary      = "A short description of STPCamera."
  s.description  = <<-DESC
  Simple camera.
                   DESC

  s.homepage     = "https://github.com/1amageek/STPCamera"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = { :type => "MIT" }
  s.author             = { "1_am_a_geek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1_am_a_geek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/1amageek/STPCamera.git", :tag => "0.1.0" }
  s.source_files  = "STPCamera/**/*.{h,m}"
  s.exclude_files = ["STPCamera/AppDelegate.*", "main.m"]
  s.public_header_files = "STPCamera/**/*.h"
  s.dependency "pop", "~> 1.0"

end
