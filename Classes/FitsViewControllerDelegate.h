//
//  FitsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FitsViewController;
@class ShipFit;
@protocol FitsViewControllerDelegate <NSObject>
- (void) fitsViewController:(FitsViewController*) controller didSelectFit:(ShipFit*) fit;
@end
