//
//  NCDBInvBlueprintType+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvBlueprintType.h"

@class NCDBRamActivity;
@interface NCDBInvBlueprintType (Neocom)
- (NSArray*) activities;
- (NSArray*) requiredSkillsForActivity:(NCDBRamActivity*) activity;
- (NSArray*) requiredMaterialsForActivity:(NCDBRamActivity*) activity;
@end
