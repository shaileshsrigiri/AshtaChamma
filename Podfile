platform :ios, '14.0'

target 'AshtaChamma' do
  use_frameworks!

  # Firebase pods
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
      config.build_settings['GCC_ENABLE_CPP_EXCEPTIONS'] = 'YES'
      config.build_settings['CLANG_CXX_LANGUAGE_DIALECT'] = 'c++17'
    end
  end

  # Fix rsync/sandbox errors by disabling code signing for simulator
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.name == 'Debug'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
