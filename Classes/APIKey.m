//
//  APIKey.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "APIKey.h"


@implementation APIKey

@synthesize apiKeyInfo = _apiKeyInfo;
@synthesize error = _error;
@synthesize assignedCharacters = _assignedCharacters;

@dynamic keyID;
@dynamic vCode;

- (void) dealloc {
	[_apiKeyInfo release];
	[_error release];
	[_assignedCharacters release];
	[super dealloc];
}

- (NSMutableArray*) assignedCharacters {
	if (!_assignedCharacters) {
		_assignedCharacters = [[NSMutableArray alloc] init];
	}
	return _assignedCharacters;
}

/*- (NSUInteger) hash {
	return self.keyID;
}

- (BOOL) isEqual:(id)object {
	return self.keyID == [object keyID];
}*/

@end
