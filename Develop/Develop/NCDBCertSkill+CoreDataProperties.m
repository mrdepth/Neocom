//
//  NCDBCertSkill+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertSkill+CoreDataProperties.h"

@implementation NCDBCertSkill (CoreDataProperties)

+ (NSFetchRequest<NCDBCertSkill *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CertSkill"];
}

@dynamic skillLevel;
@dynamic mastery;
@dynamic type;

@end
