//
//  APIKey.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "APIKey.h"
#import "EUStorage.h"


@implementation APIKey

@synthesize apiKeyInfo = _apiKeyInfo;
@synthesize error = _error;
@synthesize assignedCharacters = _assignedCharacters;

@dynamic keyID;
@dynamic vCode;

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

- (EVEAPIKeyInfo*) apiKeyInfo {
	@synchronized(self) {
		if (!_apiKeyInfo) {
			NSError* error = nil;
			_apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:self.keyID vCode:self.vCode error:&error progressHandler:nil];
			if (!_apiKeyInfo)
				_apiKeyInfo = (EVEAPIKeyInfo*) [NSNull null];
			self.error = error;
		}
		return [_apiKeyInfo isKindOfClass:[EVEAPIKeyInfo class]] ? _apiKeyInfo : nil;
	}
}

+ (NSArray*) allAPIKeys {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext]];
	return [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

@end
