//
//  NCDBInvControlTowerResourcePurpose.h
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvControlTowerResource;

@interface NCDBInvControlTowerResourcePurpose : NSManagedObject

@property (nonatomic) int32_t purposeID;
@property (nonatomic, retain) NSString * purposeText;
@property (nonatomic, retain) NSSet *controlTowerResources;
@end

@interface NCDBInvControlTowerResourcePurpose (CoreDataGeneratedAccessors)

- (void)addControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addControlTowerResources:(NSSet *)values;
- (void)removeControlTowerResources:(NSSet *)values;

@end
