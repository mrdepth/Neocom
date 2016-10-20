//
//  NCDBDgmppHullType+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppHullType+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppHullType (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppHullType *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *hullTypeName;
@property (nonatomic) float signature;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBDgmppHullType (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
