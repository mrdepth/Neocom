//
//  NCFittingEngine.h
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <eufe/eufe.h>

@class NCDBInvType;
@class NCShipFit;
@class NCPOSFit;
@interface NCFittingEngine : NSObject
@property (nonatomic, assign, readonly) std::shared_ptr<eufe::Engine> engine;
@property (nonatomic, strong, readonly) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* storageManagedObjectContext;

- (void)performBlockAndWait:(void (^)())block;
- (void)performBlock:(void (^)())block;
- (void)loadShipFit:(NCShipFit*) fit;
- (void)loadPOSFit:(NCPOSFit*) fit;

@end

@interface NCFittingEngineItemPointer : NSObject
@property (nonatomic, assign, readonly) std::shared_ptr<eufe::Item> item;

+ (instancetype) pointerWithItem:(std::shared_ptr<eufe::Item>) item;
- (id) initWithItem:(std::shared_ptr<eufe::Item>) item;
@end