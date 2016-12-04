//
//  NCProgressHandler.h
//  Neocom
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCProgressHandler : NSObject
@property (nonatomic, strong, readonly) NSProgress* progress;

+ (NCProgressHandler*) progressHandlerForViewController:(UIViewController*) controller withTotalUnitCount:(int64_t)unitCount;
- (id) initForViewController:(UIViewController*) controller withTotalUnitCount:(int64_t)unitCount;
- (void) finish;

@end
