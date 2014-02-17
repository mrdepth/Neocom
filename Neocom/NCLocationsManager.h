//
//  NCLocationsManager.h
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@interface NCLocationsManagerItem : NSObject<NSCoding>
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
- (id) initWithName:(NSString*) name solarSystem:(EVEDBMapSolarSystem*) solarSystem;
@end

@interface NCLocationsManager : NSObject
+ (instancetype) defaultManager;
- (NSDictionary*) locationsNamesWithIDs:(NSArray*) ids;
@end
