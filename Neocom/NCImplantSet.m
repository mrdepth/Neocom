//
//  NCImplantSet.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCImplantSet.h"

@implementation NCImplantSetData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.implantIDs = [aDecoder decodeObjectForKey:@"implantIDs"];
		self.boosterIDs = [aDecoder decodeObjectForKey:@"boosterIDs"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.implantIDs)
		[aCoder encodeObject:self.implantIDs forKey:@"implantIDs"];
	if (self.boosterIDs)
		[aCoder encodeObject:self.boosterIDs forKey:@"boosterIDs"];
}

@end

@implementation NCImplantSet

@dynamic data;
@dynamic name;


@end
