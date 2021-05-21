platform :ios, '10.0'
use_frameworks!

source 'https://github.com/appodeal/CocoaPods.git'
source 'https://cdn.cocoapods.org/'

def appodeal
  pod 'APDAdColonyAdapter', '2.9.0.0-Beta'
      pod 'APDAmazonAdsAdapter', '2.9.0.0-Beta'
      pod 'APDAppLovinAdapter', '2.9.0.0-Beta'
      pod 'APDBidMachineAdapter', '2.9.0.0-Beta'
      pod 'APDFacebookAudienceAdapter', '2.9.0.0-Beta'
      pod 'APDGoogleAdMobAdapter', '2.9.0.0-Beta'
      pod 'APDIronSourceAdapter', '2.9.0.0-Beta'
      pod 'APDMyTargetAdapter', '2.9.0.0-Beta'
      pod 'APDOguryAdapter', '2.9.0.0-Beta'
      pod 'APDSmaatoAdapter', '2.9.0.0-Beta'
      pod 'APDStartAppAdapter', '2.9.0.0-Beta'
      pod 'APDUnityAdapter', '2.9.0.0-Beta'
      pod 'APDVungleAdapter', '2.9.0.0-Beta'
      pod 'APDYandexAdapter', '2.9.0.0-Beta'
end

target 'Neocom' do
    project './Neocom/Neocom.xcodeproj'
#    pod 'StackConsentManager', '~> 1.0.1'
#    appodeal
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
