//
//  NCDBIndBlueprintType.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndActivity, NCDBInvType;

@interface NCDBIndBlueprintType : NSManagedObject

@property (nonatomic) int32_t maxProductionLimit;
@property (nonatomic, retain) NCDBInvType *type;
@property (nonatomic, retain) NSSet *activities;
@end

@interface NCDBIndBlueprintType (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(NCDBIndActivity *)value;
- (void)removeActivitiesObject:(NCDBIndActivity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

@end
