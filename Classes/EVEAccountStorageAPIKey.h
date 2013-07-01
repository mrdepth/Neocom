//
//  EVEAccountStorageAPIKey.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEOnlineAPI.h"

@interface EVEAccountStorageAPIKey: NSObject
@property (nonatomic, strong) EVEAPIKeyInfo *apiKeyInfo;
@property (nonatomic) NSInteger keyID;
@property (nonatomic, copy) NSString *vCode;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableArray *assignedCharacters;

@end
