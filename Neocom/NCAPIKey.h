//
//  NCAPIKey.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class EVEAPIKeyInfo;

@interface NCAPIKey : NSManagedObject

@property (nonatomic) int32_t keyID;
@property (nonatomic, strong) NSString * vCode;

@property (nonatomic, strong) EVEAPIKeyInfo* apiKeyInfo;
@property (nonatomic, strong) NSError* error;

+ (instancetype) apiKeyWithKeyID:(NSInteger) keyID;

@end
