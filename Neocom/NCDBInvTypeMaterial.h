//
//  NCDBInvTypeMaterial.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvBlueprintType, NCDBInvType;

@interface NCDBInvTypeMaterial : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprintType;
@property (nonatomic, retain) NCDBInvType *materialType;

@end
