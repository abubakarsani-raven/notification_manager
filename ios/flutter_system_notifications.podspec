#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_system_notifications.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_system_notifications'
  s.version          = '1.0.3'
  s.summary          = 'A high-quality, cross-platform Flutter plugin for managing system-level local notifications with advanced features like scheduling, action buttons, and deep linking.'
  s.description      = <<-DESC
A high-quality, cross-platform Flutter plugin for managing system-level local notifications with advanced features like scheduling, action buttons, and deep linking.
                       DESC
  s.homepage         = 'https://github.com/abubakarsani-raven/flutter_system_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_system_notifications_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end 