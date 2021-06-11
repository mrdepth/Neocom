platform :ios, '10.0'
use_frameworks!

source 'https://github.com/appodeal/CocoaPods.git'
source 'https://cdn.cocoapods.org/'

def appodeal
  pod 'APDAdColonyAdapter', '2.10.1.1'
      pod 'APDAmazonAdsAdapter', '2.10.1.1'
      pod 'APDAppLovinAdapter', '2.10.1.2'
      pod 'APDBidMachineAdapter', '2.10.1.1'
      pod 'APDFacebookAudienceAdapter', '2.10.1.1'
      pod 'APDGoogleAdMobAdapter', '2.10.1.1'
      pod 'APDIronSourceAdapter', '2.10.1.1'
      pod 'APDMyTargetAdapter', '2.10.1.1'
      pod 'APDOguryAdapter', '2.10.1.1'
      pod 'APDSmaatoAdapter', '2.10.1.1'
      pod 'APDStartAppAdapter', '2.10.1.2'
      pod 'APDUnityAdapter', '2.10.1.1'
      pod 'APDVungleAdapter', '2.10.1.1'
      pod 'APDYandexAdapter', '2.10.1.1'
end

target 'Neocom' do
    project './Neocom/Neocom.xcodeproj'
    pod 'StackConsentManager', '~> 1.1.0'
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
