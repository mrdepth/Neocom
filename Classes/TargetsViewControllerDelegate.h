//
//  TargetsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "eufe.h"

@class TargetsViewController;
@class Fit;
@protocol TargetsViewControllerDelegate <NSObject>
- (void) targetsViewController:(TargetsViewController*) controller didSelectTarget:(eufe::Ship*) target;
@end
