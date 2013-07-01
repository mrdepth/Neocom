//
//  Character.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Character.h"

@interface Character()


@end

@implementation Character

+ (NSString*) charactersDirectory {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FittingCharacters"];
}

- (NSString*) guid {
	return nil;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.characterID = [aDecoder decodeIntegerForKey:@"characterID"];
		self.skills = [aDecoder decodeObjectForKey:@"skills"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeInteger:self.characterID forKey:@"characterID"];
	[aCoder encodeObject:self.skills forKey:@"skills"];
}

- (BOOL) isEqual:(id)object {
	return [object isMemberOfClass:[self class]] && [object characterID] == self.characterID;
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
