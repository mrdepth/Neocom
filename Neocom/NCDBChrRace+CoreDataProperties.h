//
//  NCDBChrRace+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBChrRace.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBChrRace (CoreDataProperties)

@property (nonatomic) int32_t raceID;
@property (nullable, nonatomic, retain) NSString *raceName;
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
