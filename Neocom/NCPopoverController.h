//
//  NCPopoverController.h
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCPopoverController : UIPopoverController<UIPopoverControllerDelegate>
@property (nonatomic, weak) UIViewController* presentingViewController;
@end
