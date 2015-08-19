//
//  NCDBInvType+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType.h"

#define NCShipCategoryID 6
#define NCChargeCategoryID 8
#define NCModuleCategoryID 7
#define NCSubsystemCategoryID 32
#define NCDroneCategoryID 18


typedef NS_ENUM(NSInteger, NCTypeCategory) {
	NCTypeCategoryUnknown,
	NCTypeCategoryModule,
	NCTypeCategoryCharge,
	NCTypeCategoryDrone
};

@interface NCDBInvType (Neocom)
@property (nonatomic, readonly) NSString* metaGroupName;

+ (instancetype) invTypeWithTypeID:(int32_t) typeID;
+ (instancetype) invTypeWithTypeName:(NSString*) typeName;
- (NSDictionary*) attributesDictionary;
- (NSDictionary*) effectsDictionary;

- (int32_t) slot;
- (NCTypeCategory) category;
@end
