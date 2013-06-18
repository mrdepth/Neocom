//
//  EVEAccountStorageCharacter.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorageCharacter.h"


@implementation EVEAccountStorageCharacter

- (NSUInteger) hash {
	return self.characterID;
}

- (BOOL) isEqual:(id)object {
	return self.characterID == [object characterID];
}

- (EVEAccountStorageAPIKey*) anyCharAPIKey {
	if (self.assignedCharAPIKeys.count == 0)
		return nil;
	else
		return [self.assignedCharAPIKeys objectAtIndex:0];
}

- (EVEAccountStorageAPIKey*) anyCorpAPIKey {
	if (self.assignedCorpAPIKeys.count == 0)
		return nil;
	else
		return [self.assignedCorpAPIKeys objectAtIndex:0];
}


@end
