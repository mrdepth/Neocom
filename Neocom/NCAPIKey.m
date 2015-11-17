//
//  NCAPIKey.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCAPIKey.h"
#import "NCCache.h"
#import <EVEAPI/EVEAPI.h>

@implementation NCAPIKey

@dynamic keyID;
@dynamic vCode;
@dynamic accounts;
@dynamic apiKeyInfo;

@synthesize error = _error;

@end
