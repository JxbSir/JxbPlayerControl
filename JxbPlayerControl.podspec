Pod::Spec.new do |s|

  s.name         = "JxbPlayerControl"
  s.version      = "1.0"
  s.summary      = "Mp3 Player Control"
  s.homepage     = "https://github.com/JxbSir"
  s.license      = "Peter"
  s.author       = { "Peter" => "i@jxb.name" }
  s.requires_arc = true
  s.source       = { :git => "https://github.com/JxbSir/JxbPlayerControl.git"  }
  s.source_files = "JxbPlayerControl/JxbPlayer/*.{h,m}"
  s.public_header_files = 'JxbPlayerControl/JxbPlayer/JxbPlayer.h'
  s.frameworks   = 'UIKit'
end
