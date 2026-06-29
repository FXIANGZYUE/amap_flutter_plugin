Pod::Spec.new do |s|
  s.name             = 'amap_flutter_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Amap Flutter plugin with location support.'
  s.description      = <<-DESC
Amap Flutter plugin with map, route, and location support.
                       DESC
  s.homepage         = 'https://github.com/FXIANGZYUE/amap_flutter_plugin'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AMapLocation', '~> 6.0.0'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
