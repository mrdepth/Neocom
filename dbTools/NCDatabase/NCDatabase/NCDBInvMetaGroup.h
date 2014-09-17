//
//  NCDBInvMetaGroup.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvType;

@interface NCDBInvMetaGroup : NSManagedObject

@property (nonatomic) int32_t metaGroupID;
@property (nonatomic, retain) NSString * metaGroupName;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBInvMetaGroup (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
