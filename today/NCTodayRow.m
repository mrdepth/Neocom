//
//  NCTodayRow.m
//  Neocom
//
//  Created by Артем Шиманский on 28.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTodayRow.h"

@implementation NCTodayRow

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeObject:self.skillQueueEndDate forKey:@"skillQueueEndDate"];
	if (self.image)
		[aCoder encodeObject:UIImagePNGRepresentation(self.image) forKey:@"image"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.skillQueueEndDate = [aDecoder decodeObjectForKey:@"skillQueueEndDate"];
		self.image = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"image"]];
	}
	return self;
}

@end
