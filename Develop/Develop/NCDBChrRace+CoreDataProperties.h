//
//  NCDBChrRace+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBChrRace+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBChrRace (CoreDataProperties)

+ (NSFetchRequest<NCDBChrRace *> *)fetchRequest;

@property (nonatomic) int32_t raceID;
@property (nullable, nonatomic, copy) NSString *raceName;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmppItemCategory *> *dgmppCategories;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *types;

@end

@interface NCDBChrRace (CoreDataGeneratedAccessors)

- (void)addDgmppCategoriesObject:(NCDBDgmppItemCategory *)value;
- (void)removeDgmppCategoriesObject:(NCDBDgmppItemCategory *)value;
- (void)addDgmppCategories:(NSSet<NCDBDgmppItemCategory *> *)values;
- (void)removeDgmppCategories:(NSSet<NCDBDgmppItemCategory *> *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet<NCDBInvType *> *)values;
- (void)removeTypes:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END
