platform :ios, '14.0'

target 'AshtaChamma' do
  use_frameworks!

  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Database'

  target 'AshtaChammaTests' do
    inherit! :search_paths
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
