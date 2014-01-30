//
//  NCLoadout.h
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCLoadoutData;
@class EVEDBInvType;

@interface NCLoadout : NSManagedObject

@property (nonatomic, retain) NSString * loadoutName;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic) int32_t typeID;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NCLoadoutData *data;

@property (nonatomic, readonly, strong) EVEDBInvType* type;

@end
