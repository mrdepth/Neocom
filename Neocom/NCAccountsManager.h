//
//  NCAccountsManager.h
//  Neocom
//
//  Created by Artem Shimanski on 18.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCAccountsManager : NSObject
@property (nonatomic, strong, readonly) NSArray* accounts;

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;
- (void) removeAPIKeyWithKeyID:(NSInteger) keyID;

@end
