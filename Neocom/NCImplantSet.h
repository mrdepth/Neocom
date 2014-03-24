//
//  NCImplantSet.h
//  Neocom
//
//  Created by Артем Шиманский on 24.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NCImplantSetData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* implantIDs;
@property (nonatomic, strong) NSArray* boosterIDs;
@end

@interface NCImplantSet : NSManagedObject

@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSString * name;

+ (NSArray*) implantSets;

@end
