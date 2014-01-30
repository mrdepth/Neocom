//
//  NCFit.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCFit.h"

@implementation NCFit

@dynamic fitName;
@dynamic imageName;
@dynamic typeID;
@dynamic typeName;
@dynamic url;
@dynamic loadout;

- (void) awakeFromInsert {
	if (!self.loadout.managedObjectContext)
		[self.managedObjectContext insertObject:self.loadout];
}

@end
