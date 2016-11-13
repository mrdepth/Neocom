//
//  NCMainMenuContainerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#define NCMainMenuDropDownSegueAnimationDuration 0.35f

@interface NCMainMenuContainerViewController : UIViewController
- (IBAction)unwindToMainMenu:(UIStoryboardSegue*)sender;
@end
