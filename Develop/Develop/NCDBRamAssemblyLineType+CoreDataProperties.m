//
//  NCDBRamAssemblyLineType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamAssemblyLineType+CoreDataProperties.h"

@implementation NCDBRamAssemblyLineType (CoreDataProperties)

+ (NSFetchRequest<NCDBRamAssemblyLineType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RamAssemblyLineType"];
}

@dynamic assemblyLineTypeID;
@dynamic assemblyLineTypeName;
@dynamic baseMaterialMultiplier;
@dynamic baseTimeMultiplier;
@dynamic minCostPerHour;
@dynamic volume;
@dynamic activity;
@dynamic installationTypeContents;

@end
