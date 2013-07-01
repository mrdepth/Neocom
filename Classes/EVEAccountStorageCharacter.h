//
//  EVEAccountStorageCharacter.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEOnlineAPI.h"

@class EVEAccountStorageAPIKey;
@interface EVEAccountStorageCharacter: EVEAPIKeyInfoCharactersItem
@property (nonatomic, strong) NSMutableArray *assignedCharAPIKeys;
@property (nonatomic, strong) NSMutableArray *assignedCorpAPIKeys;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, readonly) EVEAccountStorageAPIKey *anyCharAPIKey;
@property (nonatomic, readonly) EVEAccountStorageAPIKey *anyCorpAPIKey;

@end
