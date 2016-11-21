//
//  NCManagedObjectObserver.h
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

typedef NS_ENUM(NSInteger, NCManagedObjectObserverAction) {
	NCManagedObjectObserverActionUpdate,
	NCManagedObjectObserverActionDelete
};

@interface NCManagedObjectObserver : NSObject
+ (instancetype) observerWithObjectID:(NSManagedObjectID*) objectID block:(void(^)(NCManagedObjectObserverAction action)) block;
- (instancetype) initWithObjectID:(NSManagedObjectID*) objectID block:(void(^)(NCManagedObjectObserverAction action)) block;
@end
