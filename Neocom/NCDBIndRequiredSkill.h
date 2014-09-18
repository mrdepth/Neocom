//
//  NCDBIndRequiredSkill.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndActivity, NCDBInvType;

@interface NCDBIndRequiredSkill : NSManagedObject

@property (nonatomic) int16_t skillLevel;
@property (nonatomic, retain) NCDBIndActivity *activity;
@property (nonatomic, retain) NCDBInvType *skillType;

@end
