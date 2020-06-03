platform :ios, '9.0'
use_frameworks!

def appodeal
    pod 'APDAmazonAdsAdapter', '2.7.1.1-Beta'
    pod 'APDAppLovinAdapter', '2.7.1.1-Beta'
    pod 'APDAppodealAdExchangeAdapter', '2.7.1.1-Beta'
    pod 'APDFacebookAudienceAdapter', '2.7.1.1-Beta'
    pod 'APDGoogleAdMobAdapter', '2.7.1.1-Beta'
    pod 'APDInMobiAdapter', '2.7.1.1-Beta'
    pod 'APDInnerActiveAdapter', '2.7.1.1-Beta'
    pod 'APDMyTargetAdapter', '2.7.1.1-Beta'
    pod 'APDOpenXAdapter', '2.7.1.1-Beta'
    pod 'APDPubnativeAdapter', '2.7.1.1-Beta'
    pod 'APDSmaatoAdapter', '2.7.1.1-Beta'
    pod 'APDStartAppAdapter', '2.7.1.1-Beta'
    pod 'APDUnityAdapter', '2.7.1.1-Beta'
    pod 'APDYandexAdapter', '2.7.1.1-Beta'
end

target 'Neocom' do
    project './Neocom/Neocom.xcodeproj'
    pod 'StackConsentManager', '~> 1.0.0'
    appodeal
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig.sub!('OTHER_LDFLAGS', 'OTHER_LDFLAGS[sdk=iphone*]')
      File.open(xcconfig_path, "w") { |file| file << xcconfig }
#      puts config.build_settings
#      puts "\n***\n"
#      config.build_settings['OTHER_LDFLAGS'] = '$(inherited)'
    end
  end
end
