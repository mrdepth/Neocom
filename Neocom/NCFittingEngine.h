//
//  NCFittingEngine.h
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "eufe.h"

@class NCDBInvType;
@class NCShipFit;
@interface NCFittingEngine : NSObject
@property (nonatomic, assign, readonly) eufe::Engine* engine;
@property (nonatomic, strong, readonly) NSManagedObjectContext* databaseManagedObjectContext;

- (void)performBlockAndWait:(void (^)())block;
- (NCDBInvType*) invTypeWithTypeID:(int32_t) typeID;
- (void) loadShipFit:(NCShipFit*) fit;

@end
