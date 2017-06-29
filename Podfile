use_frameworks!

target 'RxMovies' do
    pod 'RxSwift', '~> 3.1.0'
    pod 'RxCocoa', '~> 3.1.0'
    pod 'Kingfisher', '~> 3.0'
    pod 'ContourProgressView'
end

# enable tracing resources

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'RxSwift'
      target.build_configurations.each do |config|
        if config.name == 'Debug'
          config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
        end
      end
    end
  end
end
