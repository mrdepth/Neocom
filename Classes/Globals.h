//
//  Globals.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEUniverseAppDelegate.h"

#define EVEAccountDidSelectNotification @"EVEAccountDidSelectNotification"
#define EVEAccountDidUpdateNotification @"EVEAccountDidUpdateNotification"
#define NotificationAccountStoargeDidChange @"NotificationAccountStoargeDidChange"
#define NotificationReadMail @"NotificationReadMail"
#define RETINA_DISPLAY ([[UIScreen mainScreen] scale] == 2.0)

#define SettingsPublishedFilterKey @"SettingsPublishedFilterKey"
#define SettingsCurrentAccount @"SettingsCurrentAccount"
#define SettingsCurrentCharacterID @"SettingsCurrentCharacterID"
#define SettingsNoAds @"SettingsNoAds"
#define SettingsWalletTransactionsOwner @"SettingsWalletTransactionsOwner"
#define SettingsWalletTransactionsCorpAccount @"SettingsWalletTransactionsCorpAccount"
#define SettingsWalletJournalOwner @"SettingsWalletJournalOwner"
#define SettingsWalletJournalCorpAccount @"SettingsWalletJournalCorpAccount"
#define SettingsMarketOrdersOwner @"SettingsMarketOrdersOwner"
#define SettingsContractsOwner @"SettingsContractsOwner"
#define SettingsIndustryJobsOwner @"SettingsIndustryJobsOwner"
#define SettingsAssetsOwner @"SettingsAssetsOwner"
#define SettingsTipsMarketInfo @"SettingsTipsMarketInfo"
#define SettingsTipsAddAccount @"SettingsTipsAddAccount"
#define SettingsTipsPosFuel @"SettingsTipsPosFuel"
#define SettingsUseCloud @"SettingsUseCloud"
#define SettingsCloudToken @"SettingsCloudToken"
#define SettingsNeocomAPINextSyncDate @"SettingsNeocomAPINextSyncDate"
#define SettingsNeocomAPIAlwaysUploadFits @"SettingsNeocomAPIAlwaysUploadFits"
#define SettingsOfflineMode @"SettingsOfflineMode"
#define SettingsUDID @"SettingsUDID"

#define SkillTreeRequirementIDKey @"requirementID"
#define SkillTreeSkillLevelIDKey @"skillLevelID"

#define BattleClinicAPIKey @"D8368891670D2D7079B17A59B4268C0B95D663FF"


@interface Globals : NSObject {

}
+ (NSString*) documentsDirectory;
+ (NSString*) cachesDirectory;
+ (NSString*) accountsFilePath;
+ (NSString*) fitsFilePath;
+ (EVEUniverseAppDelegate*) appDelegate;

@end

extern float SYSTEM_VERSION;