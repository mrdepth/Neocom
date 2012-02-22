//
//  FilterViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FilterViewController;
@class EUFilter;
@protocol FilterViewControllerDelegate <NSObject>
- (void) filterViewController:(FilterViewController*) controller didApplyFilter:(EUFilter*) filter;
- (void) filterViewControllerDidCancel:(FilterViewController*) controller;
@end
