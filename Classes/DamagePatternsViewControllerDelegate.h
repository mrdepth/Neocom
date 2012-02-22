//
//  DamagePatternsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DamagePatternsViewController;
@class DamagePattern;
@protocol DamagePatternsViewControllerDelegate <NSObject>

- (void) damagePatternsViewController:(DamagePatternsViewController*) controller didSelectDamagePattern:(DamagePattern*) damagePattern;

@end
