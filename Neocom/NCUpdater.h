//
//  NCUpdater.h
//  Neocom
//
//  Created by Artem Shimanski on 18.10.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCUpdater : NSObject
@property (nonatomic, strong, readonly) NSProgress* progress;
@property (nonatomic, strong) NSError* error;

+ (instancetype) sharedUpdater;

- (void) checkUpdates;
- (NSInteger) applicationVersion;

@end
