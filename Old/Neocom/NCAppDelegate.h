//
//  NCAppDelegate.h
//  Neocom
//
//  Created by Artem Shimanski on 27.11.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void) reconnectStoreIfNeeded;

@end
