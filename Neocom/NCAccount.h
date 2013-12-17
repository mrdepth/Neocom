//
//  NCAccount.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAPIKey.h"

typedef enum {
	NCAccountTypeCharacter,
	NCAccountTypeCorporate
} NCAccountType;

@interface NCAccount : NSObject<NSCoding>
@property (nonatomic, strong) NCAPIKey* apiKey;
@property (nonatomic, assign, readonly) NCAccountType accountType;
//@property (nonatomic, strong) NCAccountCharacter* character;
@property (nonatomic, assign) NSInteger order;


@end
