//
//  NCDBChrRace.h
//  Neocom
//
//  Created by Артем Шиманский on 16.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon, NCDBInvType;

@interface NCDBChrRace : NSManagedObject

@property (nonatomic) int32_t raceID;
@property (nonatomic, retain) NSString * raceName;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *types;
@end

@interface NCDBChrRace (CoreDataGeneratedAccessors)

- (void)addTypesObject:(NCDBInvType *)value;
- (void)removeTypesObject:(NCDBInvType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
