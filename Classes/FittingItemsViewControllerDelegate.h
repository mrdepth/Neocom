//
//  FittingItemsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FittingItemsViewController;
@class EVEDBInvType;
@protocol FittingItemsViewControllerDelegate
- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type;
@end
