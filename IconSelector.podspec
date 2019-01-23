Pod::Spec.new do |s|
  s.name         = "IconSelector"
  s.version      = "0.1"
  s.summary      = "Fancy view to enable the selection of alternate icons."
  s.homepage     = "https://github.com/jellybeansoup/ios-icon-selector"
  s.license      = { :type => 'BSD', :file => 'LICENSE' }
  s.author       = { "Daniel Farrelly" => "daniel@jellystyle.com" }
  s.source       = { :git => "https://github.com/jellybeansoup/ios-icon-selector.git", :tag => "v#{s.version}" }
  s.ios.deployment_target = '10.3'
  s.source_files = "src/IconSelector/*.{swift,h}"
  s.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
end
