//
//  NCDBRamActivity.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBIndActivity, NCDBRamAssemblyLineType;

@interface NCDBRamActivity : NSManagedObject

@property (nonatomic) int32_t activityID;
@property (nonatomic, retain) NSString * activityName;
@property (nonatomic) BOOL published;
@property (nonatomic, retain) NSSet *assemblyLineTypes;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *indActivities;
@end

@interface NCDBRamActivity (CoreDataGeneratedAccessors)

- (void)addAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)removeAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)addAssemblyLineTypes:(NSSet *)values;
- (void)removeAssemblyLineTypes:(NSSet *)values;

- (void)addIndActivitiesObject:(NCDBIndActivity *)value;
- (void)removeIndActivitiesObject:(NCDBIndActivity *)value;
- (void)addIndActivities:(NSSet *)values;
- (void)removeIndActivities:(NSSet *)values;

@end
