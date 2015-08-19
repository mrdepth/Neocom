//
//  NCStorage.h
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NCStorageDidChangeNotification @"NCStorageDidChangeNotification"

#define NCSettingsDontNeedsCloudTransfer @"NCSettingsDontNeedsCloudTransfer"
#define NCSettingsDontNeedsCloudReset @"NCSettingsDontNeedsCloudReset"
#define NCSettingsStorageType @"NCSettingsStorageType"
#define NCSettingsUseCloudKey @"NCSettingsUseCloudKey"
#define NCSettingsCloudTokenKey @"NCSettingsCloudTokenKey"
#define NCSettingsMigratedToCloudKey @"NCSettingsMigratedToCloudKey"

typedef NS_ENUM(NSInteger, NCStorageType) {
	NCStorageTypeFallback,
	NCStorageTypeCloud
};


@interface NCStorage : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign, readonly) NCStorageType storageType;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;

+ (instancetype) sharedStorage;
+ (instancetype) fallbackStorage;
+ (instancetype) cloudStorage;

+ (void) setSharedStorage:(NCStorage*) storage;
- (void) saveContext;

- (id) initFallbackStorage;
- (id) initCloudStorage;
- (BOOL) transferDataFromFallbackToCloud;

- (BOOL) backupCloudData;
- (BOOL) restoreCloudData;

- (void) removeDuplicatesFromPersistentStoreCoordinator:(NSPersistentStoreCoordinator*) persistentStoreCoordinator;

@end
