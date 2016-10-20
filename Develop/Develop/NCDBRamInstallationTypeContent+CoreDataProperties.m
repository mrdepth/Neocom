//
//  NCDBRamInstallationTypeContent+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamInstallationTypeContent+CoreDataProperties.h"

@implementation NCDBRamInstallationTypeContent (CoreDataProperties)

+ (NSFetchRequest<NCDBRamInstallationTypeContent *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RamInstallationTypeContent"];
}

@dynamic quantity;
@dynamic assemblyLineType;
@dynamic installationType;

@end
