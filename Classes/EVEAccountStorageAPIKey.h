//
//  EVEAccountStorageAPIKey.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEOnlineAPI.h"

@interface EVEAccountStorageAPIKey: NSObject {
	EVEAPIKeyInfo *apiKeyInfo;
	NSInteger keyID;
	NSString *vCode;
	NSError *error;
	NSMutableArray *assignedCharacters;
}
@property (nonatomic, retain) EVEAPIKeyInfo *apiKeyInfo;
@property (nonatomic) NSInteger keyID;
@property (nonatomic, copy) NSString *vCode;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSMutableArray *assignedCharacters;

@end
