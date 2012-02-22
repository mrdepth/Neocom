//
//  DronesAmountViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DronesAmountViewController;
@protocol DronesAmountViewControllerDelegate

- (void) dronesAmountViewController:(DronesAmountViewController*) controller didSelectAmount:(NSInteger) amount;
- (void) dronesAmountViewControllerDidCancel:(DronesAmountViewController*) controller;

@end
