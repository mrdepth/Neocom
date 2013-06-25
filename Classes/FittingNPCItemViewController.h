//
//  FittingNPCItemViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ItemViewController.h"
#import "DamagePatternsViewController.h"

@interface FittingNPCItemViewController : ItemViewController
@property (nonatomic, assign) DamagePatternsViewController* damagePatternsViewController;

- (IBAction)onDone:(id)sender;

@end
