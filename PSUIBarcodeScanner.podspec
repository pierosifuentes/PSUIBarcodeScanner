Pod::Spec.new do |s|

  s.name         = "PSUIBarcodeScanner"
  s.version      = "1.0.2"
  s.summary      = "Simple and fully customizable barcode scanner written in Swift"

  s.description  = <<-DESC
                  PSUIBarcodeScanner helps you scanning any kind of barcode 2d and linear kinds.
                   DESC

  s.homepage     = "https://github.com/piero9212/PSUIBarcodeScanner"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Piero Sifuentes" => "piero9212@gmail.com" }
  s.social_media_url   = "https://twitter.com/piero_sifuentes"
  s.platform     = :ios, "10.0"
  s.requires_arc = true
  s.source       = { :git => "https://github.com/piero9212/PSUIBarcodeScanner.git", :tag => "#{s.version}" }
  s.source_files       = 'PSUIBarcodeScanner/PSUIBarcodeScanner/**/*.swift'
  s.frameworks   = 'UIKit', 'AVFoundation'


end
