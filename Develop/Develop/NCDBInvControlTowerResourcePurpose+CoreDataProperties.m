//
//  NCDBInvControlTowerResourcePurpose+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTowerResourcePurpose+CoreDataProperties.h"

@implementation NCDBInvControlTowerResourcePurpose (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTowerResourcePurpose *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvControlTowerResourcePurpose"];
}

@dynamic purposeID;
@dynamic purposeText;
@dynamic controlTowerResources;

@end
