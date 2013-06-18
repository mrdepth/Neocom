//
//  EVEAccountStorage.h
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEAccountStorageAPIKey.h"
#import "EVEAccountStorageCharacter.h"

@interface EVEAccountStorage : NSObject
@property (nonatomic, readonly, strong) NSMutableDictionary *apiKeys;
@property (nonatomic, readonly, strong) NSMutableDictionary *characters;
@property (nonatomic, readonly, strong) NSMutableDictionary *ignored;

+ (EVEAccountStorage*) sharedAccountStorage;

- (void) reload;
- (void) save;

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;
- (void) removeAPIKey:(NSInteger) keyID;
@end
