//
//  NCStorage.h
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCStorageType) {
	NCStorageTypeFallback,
	NCStorageTypeCloud
};


@interface NCStorage : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign, readonly) NCStorageType storageType;

+ (id) sharedStorage;
+ (id) fallbackStorage;
+ (id) cloudStorage;

+ (void) setSharedStorage:(NCStorage*) storage;
- (void) saveContext;

- (id) initFallbackStorage;
- (id) initCloudStorage;
- (BOOL) transferDataFromFallbackToCloud;
@end
