//
//  NCDBInvMetaGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvMetaType;

@interface NCDBInvMetaGroup : NSManagedObject

@property (nonatomic) int32_t metaGroupID;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *metaTypes;
@end

@interface NCDBInvMetaGroup (CoreDataGeneratedAccessors)

- (void)addMetaTypesObject:(NCDBInvMetaType *)value;
- (void)removeMetaTypesObject:(NCDBInvMetaType *)value;
- (void)addMetaTypes:(NSSet *)values;
- (void)removeMetaTypes:(NSSet *)values;

@end
