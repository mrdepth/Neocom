//
//  NCDBInvControlTower.h
//  NCDatabase
//
//  Created by Артем Шиманский on 16.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvControlTowerResource, NCDBInvType;

@interface NCDBInvControlTower : NSManagedObject

@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) NCDBInvType *type;
@end

@interface NCDBInvControlTower (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
