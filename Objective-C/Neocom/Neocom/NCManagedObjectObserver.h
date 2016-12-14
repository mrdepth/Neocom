//
//  NCManagedObjectObserver.h
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface NCManagedObjectObserver : NSObject
+ (instancetype) observerWithHandler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block;
+ (instancetype) observerWithObjectID:(NSManagedObjectID*) objectID handler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block;
- (instancetype) initWithHandler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block;
- (instancetype) initWithObjectID:(NSManagedObjectID*) objectID handler:(void(^)(NSSet<NSManagedObjectID*>* updated, NSSet<NSManagedObjectID*>* deleted)) block;
- (void) addObjectID:(NSManagedObjectID*) objectID;
- (void) removeObjectID:(NSManagedObjectID*) objectID;

@end
i
