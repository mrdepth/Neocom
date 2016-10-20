//
//  NCAPIKey+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAPIKey+CoreDataProperties.h"

@implementation NCAPIKey (CoreDataProperties)

+ (NSFetchRequest<NCAPIKey *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"APIKey"];
}

@dynamic apiKeyInfo;
@dynamic keyID;
@dynamic vCode;
@dynamic accounts;

@end
