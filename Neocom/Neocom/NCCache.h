//
//  NCCache.h
//  Neocom
//
//  Created by Artem Shimanski on 19.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCache+CoreDataModel.h"
@import CoreData;

@interface NCCache : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (class, nonatomic, strong) NCCache* sharedCache;

- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;
- (void)storeObject:(id<NSSecureCoding>) object forKey:(NSString*) key account:(NSString*) account date:(NSDate*) date expireDate:(NSDate*) expireDate error:(NSError*) error completionHandler:(void(^)(NSManagedObjectID* objectID)) block;

@end
