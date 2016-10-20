//
//  NCDBCertCertificate+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertCertificate+CoreDataProperties.h"

@implementation NCDBCertCertificate (CoreDataProperties)

+ (NSFetchRequest<NCDBCertCertificate *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CertCertificate"];
}

@dynamic certificateID;
@dynamic certificateName;
@dynamic certificateDescription;
@dynamic group;
@dynamic masteries;
@dynamic types;

@end
