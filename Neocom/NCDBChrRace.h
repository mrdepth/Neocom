//
//  NCDBChrRace.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEufeItemCategory, NCDBEveIcon, NCDBInvType;

@interface NCDBChrRace : NSManagedObject

@property (nonatomic) int32_t raceID;
@property (nonatomic, retain) NSString * raceName;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *types;
@property (nonatomic, retain) NSSet *eufeCategories;
@end

@interface NCDBChrRace (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

- (void)addEufeCategoriesObject:(NCDBEufeItemCategory *)value;
- (void)removeEufeCategoriesObject:(NCDBEufeItemCategory *)value;
- (void)addEufeCategories:(NSSet *)values;
- (void)removeEufeCategories:(NSSet *)values;

@end
