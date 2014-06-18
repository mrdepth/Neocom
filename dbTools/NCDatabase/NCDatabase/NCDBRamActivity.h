//
//  NCDBRamActivity.h
//  NCDatabase
//
//  Created by Артем Шиманский on 18.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBRamAssemblyLineType, NCDBRamTypeRequirement;

@interface NCDBRamActivity : NSManagedObject

@property (nonatomic) int32_t activityID;
@property (nonatomic, retain) NSString * activityName;
@property (nonatomic) BOOL published;
@property (nonatomic, retain) NSSet *assemblyLineTypes;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *typeRequirements;
@end

@interface NCDBRamActivity (CoreDataGeneratedAccessors)

- (void)addAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)removeAssemblyLineTypesObject:(NCDBRamAssemblyLineType *)value;
- (void)addAssemblyLineTypes:(NSSet *)values;
- (void)removeAssemblyLineTypes:(NSSet *)values;

- (void)addTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)removeTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)addTypeRequirements:(NSSet *)values;
- (void)removeTypeRequirements:(NSSet *)values;

@end
