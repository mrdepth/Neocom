//
//  main.m
//  Neocom
//
//  Created by Artem Shimanski on 27.11.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NCAppDelegate.h"
#import "NSObject+Debug.h"

int main(int argc, char * argv[]) {
	@autoreleasepool {
//		NSLog(@"%@", [UIStoryboardPopoverSegue allMethods]);
//		NSLog(@"%@", [UIStoryboardPopoverSegue allProperties]);
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([NCAppDelegate class]));
	}
}
