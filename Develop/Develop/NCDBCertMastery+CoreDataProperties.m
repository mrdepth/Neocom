//
//  NCDBCertMastery+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertMastery+CoreDataProperties.h"

@implementation NCDBCertMastery (CoreDataProperties)

+ (NSFetchRequest<NCDBCertMastery *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CertMastery"];
}

@dynamic certificate;
@dynamic level;
@dynamic skills;

@end
