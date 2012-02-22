//
//  Character.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Character.h"

@implementation Character
@synthesize characterID;
@synthesize name;
@synthesize skills;

+ (NSString*) charactersDirectory {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FittingCharacters"];
}

- (void) dealloc {
	[name release];
	[skills release];
	[super dealloc];
}

- (NSString*) guid {
	return nil;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		name = [[aDecoder decodeObjectForKey:@"name"] retain];
		characterID = [aDecoder decodeIntegerForKey:@"characterID"];
		skills = [[aDecoder decodeObjectForKey:@"skills"] retain];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeInteger:characterID forKey:@"characterID"];
	[aCoder encodeObject:self.skills forKey:@"skills"];
}

- (BOOL) isEqual:(id)object {
	return [object isMemberOfClass:[self class]] && [object characterID] == characterID;
}

- (void) save {
	[NSKeyedArchiver archiveRootObject:self toFile:[[[Character charactersDirectory] stringByAppendingPathComponent:self.guid] stringByAppendingPathExtension:@"plist"]];
}

- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap {
	boost::shared_ptr<std::map<eufe::TypeID, int> > levels(new std::map<eufe::TypeID, int>);
	for (NSString* key in [self.skills allKeys]) {
		(*levels)[static_cast<eufe::TypeID>([key intValue])] = [[self.skills valueForKey:key] intValue];
	}
	return levels;
}

@end
