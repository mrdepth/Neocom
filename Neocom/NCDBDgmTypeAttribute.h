//
//  NCDBDgmTypeAttribute.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmAttributeType, NCDBInvType;

@interface NCDBDgmTypeAttribute : NSManagedObject

@property (nonatomic) float value;
@property (nonatomic, retain) NCDBDgmAttributeType *attributeType;
@property (nonatomic, retain) NCDBInvType *type;

@end
