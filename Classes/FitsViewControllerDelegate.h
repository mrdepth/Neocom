//
//  FitsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FitsViewController;
@class Fit;
@protocol FitsViewControllerDelegate <NSObject>
- (void) fitsViewController:(FitsViewController*) controller didSelectFit:(Fit*) fit;
@end
