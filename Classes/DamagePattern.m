//
//  DamagePattern.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePattern.h"
#import "NSString+UUID.h"

@implementation DamagePattern
@synthesize emAmount;
@synthesize thermalAmount;
@synthesize kineticAmount;
@synthesize explosiveAmount;
@synthesize patternName;
@synthesize uuid;

+ (id) uniformDamagePattern {
	DamagePattern* damagePattern = [[[DamagePattern alloc] init] autorelease];
	damagePattern.patternName = @"Uniform";
	damagePattern.uuid = @"uniform";
	return damagePattern;
}

- (id) init {
	if (self = [super init]) {
		emAmount = thermalAmount = kineticAmount = explosiveAmount = 0.25;
		self.patternName = @"Pattern Name";
		self.uuid = [NSString uuidString];
	}
	return self;
}

- (void) dealloc {
	[patternName release];
	[uuid release];
	[super dealloc];
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:[self class]])
		return [uuid isEqual:[object uuid]];
	else
		return NO;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.patternName = [aDecoder decodeObjectForKey:@"patternName"];
		self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
		emAmount = [aDecoder decodeFloatForKey:@"emAmount"];
		thermalAmount = [aDecoder decodeFloatForKey:@"thermalAmount"];
		kineticAmount = [aDecoder decodeFloatForKey:@"kineticAmount"];
		explosiveAmount = [aDecoder decodeFloatForKey:@"explosiveAmount"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:patternName forKey:@"patternName"];
	[aCoder encodeObject:uuid forKey:@"uuid"];
	[aCoder encodeFloat:emAmount forKey:@"emAmount"];
	[aCoder encodeFloat:thermalAmount forKey:@"thermalAmount"];
	[aCoder encodeFloat:kineticAmount forKey:@"kineticAmount"];
	[aCoder encodeFloat:explosiveAmount forKey:@"explosiveAmount"];
}

@end
