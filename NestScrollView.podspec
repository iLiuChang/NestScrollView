Pod::Spec.new do |s|
  s.name         = "NestScrollView"
  s.version      = "1.0.0"
  s.summary      = "A UIScrollView with nested scrolling controls."
  s.homepage     = "https://github.com/iLiuChang/NestScrollView"
  s.license      = "MIT"
  s.authors      = { "iLiuChang" => "iliuchang@foxmail.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/iLiuChang/NestScrollView.git", :tag => s.version }
  s.requires_arc = true
  s.swift_version = "5.0"
  s.source_files = "Sources/*.{swift}"
  s.resource_bundles = { 'NestScrollView' => ['Sources/PrivacyInfo.xcprivacy'] }
end
