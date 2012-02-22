//
//  AreaEffectsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AreaEffectsViewController;
@class EVEDBInvType;
@protocol AreaEffectsViewControllerDelegate <NSObject>

- (void) areaEffectsViewController:(AreaEffectsViewController*) controller didSelectAreaEffect:(EVEDBInvType*) areaEffect;

@end
