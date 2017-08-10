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
#import "NCDBMapSolarSystem+NC.h"
#import "NCDBMapDenormalize+NC.h"
#import "NCDBStaStation+NC.h"

@interface NCDatabase : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (class, nonatomic, strong) NCDatabase* sharedDatabase;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBInvType*>* invTypes;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBEveIcon*>* eveIcons;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBMapSolarSystem*>* mapSolarSystems;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBMapDenormalize*>* mapDenormalize;
@property (nonatomic, strong, readonly) NCFetchedCollection<NCDBStaStation*>* staStations;

//+ (instancetype) sharedDatabase;
- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;
- (void)performTaskAndWait:(void (^)(NSManagedObjectContext* managedObjectContext))block;

@end
