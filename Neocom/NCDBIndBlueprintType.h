//
//  NCDBIndBlueprintType.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndActivity, NCDBInvType;

@interface NCDBIndBlueprintType : NSManagedObject

@property (nonatomic) int32_t maxProductionLimit;
@property (nonatomic, retain) NSSet *activities;
@property (nonatomic, retain) NCDBInvType *type;
@end

@interface NCDBIndBlueprintType (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(NCDBIndActivity *)value;
- (void)removeActivitiesObject:(NCDBIndActivity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

@end
