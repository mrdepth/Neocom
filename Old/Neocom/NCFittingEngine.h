//
//  NCFittingEngine.h
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dgmpp/dgmpp.h>

@class NCDBInvType;
@class NCShipFit;
@class NCPOSFit;
@class NCSpaceStructureFit;
@class NCLoadoutDataShip;
@class NCLoadoutDataSpaceStructure;
@interface NCFittingEngine : NSObject
@property (nonatomic, assign, readonly) std::shared_ptr<dgmpp::Engine> engine;
@property (nonatomic, strong, readonly) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSMutableDictionary* userInfo;

- (void)performBlockAndWait:(void (^)())block;
- (void)performBlock:(void (^)())block;
- (void)loadShipFit:(NCShipFit*) fit;
- (void)loadPOSFit:(NCPOSFit*) fit;
- (void)loadSpaceStructureFit:(NCSpaceStructureFit*) fit;
- (NCLoadoutDataShip*) loadoutDataShipWithFit:(NCShipFit*) fit;
- (NCLoadoutDataSpaceStructure*) loadoutDataSpaceStructureWithFit:(NCSpaceStructureFit*) fit;

@end

@interface NCFittingEngineItemPointer : NSObject
@property (nonatomic, assign, readonly) std::shared_ptr<dgmpp::Item> item;

+ (instancetype) pointerWithItem:(std::shared_ptr<dgmpp::Item>) item;
- (id) initWithItem:(std::shared_ptr<dgmpp::Item>) item;
@end