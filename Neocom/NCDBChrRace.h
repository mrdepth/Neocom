//
//  NCDBChrRace.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEufeItemCategory, NCDBEveIcon, NCDBIndProduct, NCDBInvType;

@interface NCDBChrRace : NSManagedObject

@property (nonatomic) int32_t raceID;
@property (nonatomic, retain) NSString * raceName;
@property (nonatomic, retain) NSSet *eufeCategories;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *products;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBChrRace (CoreDataGeneratedAccessors)

- (void)addEufeCategoriesObject:(NCDBEufeItemCategory *)value;
- (void)removeEufeCategoriesObject:(NCDBEufeItemCategory *)value;
- (void)addEufeCategories:(NSSet *)values;
- (void)removeEufeCategories:(NSSet *)values;

- (void)addProductsObject:(NCDBIndProduct *)value;
- (void)removeProductsObject:(NCDBIndProduct *)value;
- (void)addProducts:(NSSet *)values;
- (void)removeProducts:(NSSet *)values;

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
