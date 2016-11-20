//
//  NCDatabase.h
//  Neocom
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCDatabase+CoreDataModel.h"
#import "NCDBInvType+NC.h"
#import "NCDBEveIcon+NC.h"

@interface NCDatabase : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (class, nonatomic, strong) NCDatabase* sharedDatabase;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBInvType*>* invTypes;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBEveIcon*>* eveIcons;

//+ (instancetype) sharedDatabase;
- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;
- (void)performTaskAndWait:(void (^)(NSManagedObjectContext* managedObjectContext))block;

@end
