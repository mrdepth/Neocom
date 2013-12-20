//
//  NCAccountsManager.m
//  Neocom
//
//  Created by Artem Shimanski on 18.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCAccountsManager.h"
#import "NCStorage.h"

@implementation NCAccountsManager

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = storage.managedObjectContext;
	
	EVEAPIKeyInfo* apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:keyID vCode:vCode cachePolicy:NSURLRequestReloadIgnoringLocalCacheData error:errorPtr progressHandler:nil];
	
	if (apiKeyInfo) {
		__block NCAPIKey* apiKey = nil;
		[context performBlockAndWait:^{
			apiKey = [NCAPIKey apiKeyWithKeyID:keyID];
			if (apiKey)
				apiKey.vCode = vCode;
			else {
				apiKey = [[NCAPIKey alloc] initWithEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
				apiKey.keyID = keyID;
				apiKey.vCode = vCode;
			}
			apiKey.apiKeyInfo = apiKeyInfo;
		}];
		
		for (EVEAPIKeyInfoCharactersItem* character in apiKeyInfo.characters) {
			
		}
		
		return YES;
	}
	else
		return NO;
}

- (void) removeAPIKeyWithKeyID:(NSInteger) keyID {
	
}

@end
