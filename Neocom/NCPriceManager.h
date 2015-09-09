//
//  NCPriceManager.h
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NCPriceManagerDidUpdateNotification @"NCPriceManagerDidUpdateNotification"

@interface NCPriceManager : NSObject
+ (instancetype) sharedManager;
- (void) requestPriceWithType:(NSInteger) typeID completionBlock:(void(^)(NSNumber* price)) completionBlock;
- (void) requestPricesWithTypes:(NSArray*) typeIDs completionBlock:(void(^)(NSDictionary* prices)) completionBlock;
- (void) updateIfNeeded;

@end
