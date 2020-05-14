//
//  NCLocationsManager.h
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCDBMapSolarSystem;
@interface NCLocationsManagerItem : NSObject<NSCoding>
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) int32_t solarSystemID;
- (id) initWithName:(NSString*) name solarSystemID:(int32_t) solarSystemID;
@end

@interface NCLocationsManager : NSObject
+ (instancetype) defaultManager;
- (void) requestLocationsNamesWithIDs:(NSArray*) ids completionBlock:(void(^)(NSDictionary* locationsNames)) completionBlock;
@end
