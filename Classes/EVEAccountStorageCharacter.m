//
//  EVEAccountStorageCharacter.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorageCharacter.h"


@implementation EVEAccountStorageCharacter
@synthesize assignedCharAPIKeys;
@synthesize assignedCorpAPIKeys;
@synthesize enabled;

- (void) dealloc {
	[assignedCharAPIKeys release];
	[assignedCorpAPIKeys release];
	[super dealloc];
}

- (NSUInteger) hash {
	return characterID;
}

- (BOOL) isEqual:(id)object {
	return self.characterID == [object characterID];
}

- (EVEAccountStorageAPIKey*) anyCharAPIKey {
	if (assignedCharAPIKeys.count == 0)
		return nil;
	else
		return [assignedCharAPIKeys objectAtIndex:0];
}

- (EVEAccountStorageAPIKey*) anyCorpAPIKey {
	if (assignedCorpAPIKeys.count == 0)
		return nil;
	else
		return [assignedCorpAPIKeys objectAtIndex:0];
}


@end
