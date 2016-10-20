//
//  NCStorage.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAPIKey+CoreDataClass.h"
#import "NCAccount+CoreDataClass.h"
@import CoreData;

typedef NS_ENUM(NSInteger, NCStorageType) {
	NCStorageTypeLocal,
	NCStorageTypeCloud
};


@interface NCStorage : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign, readonly) NCStorageType storageType;
@property (readonly, getter=isLoaded) BOOL loaded;

+ (instancetype) sharedStorage;
+ (void) setSharedStorage:(NCStorage*) storage;
+ (instancetype) cloudStorage;
+ (instancetype) localStorage;
- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;



@end
