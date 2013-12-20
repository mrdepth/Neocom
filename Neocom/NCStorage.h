//
//  NCStorage.h
//  Neocom
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>
#import "NCFitCharacter.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCSkillPlan.h"
#import "NCIgnoredCharacter.h"
#import "NCSetting.h"
#import "NCAPIKey.h"
#import "NCFit.h"

@interface NCStorage : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id) sharedStorage;
+ (void) cleanup;
- (void) saveContext;

@end
