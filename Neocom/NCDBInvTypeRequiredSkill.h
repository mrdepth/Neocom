//
//  NCDBInvTypeRequiredSkill.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType;

@interface NCDBInvTypeRequiredSkill : NSManagedObject

@property (nonatomic) int16_t skillLevel;
@property (nonatomic, retain) NCDBInvType *skillType;
@property (nonatomic, retain) NCDBInvType *type;

@end
