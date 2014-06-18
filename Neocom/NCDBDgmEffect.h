//
//  NCDBDgmEffect.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType;

@interface NCDBDgmEffect : NSManagedObject

@property (nonatomic) int32_t effectID;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBDgmEffect (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
