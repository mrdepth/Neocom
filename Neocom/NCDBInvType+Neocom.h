//
//  NCDBInvType+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType.h"

@interface NCDBInvType (Neocom)
@property (nonatomic, readonly) NSString* metaGroupName;

+ (instancetype) invTypeWithTypeID:(int32_t) typeID;
- (NSDictionary*) attributesDictionary;
- (NSDictionary*) effectsDictionary;
@end
