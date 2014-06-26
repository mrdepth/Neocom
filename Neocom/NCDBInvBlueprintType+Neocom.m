//
//  NCDBInvBlueprintType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvBlueprintType+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBInvBlueprintType (Neocom)

- (NSArray*) activities {
	NSMutableSet* activities = [NSMutableSet new];
	for (NCDBRamTypeRequirement* requirement in self.blueprintType.typeRequirements) {
		[activities addObject:requirement.activity];
	}
	return [activities allObjects];
}

- (NSArray*) requiredSkillsForActivity:(NCDBRamActivity*) activity {
	return [[self.blueprintType.typeRequirements filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"activity == %@ && requiredType.group.category.categoryID == 16", activity]] allObjects];
}

- (NSArray*) requiredMaterialsForActivity:(NCDBRamActivity*) activity {
	return [[self.blueprintType.typeRequirements filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"activity == %@ && requiredType.group.category.categoryID <> 16", activity]] allObjects];
}

@end
