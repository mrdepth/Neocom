//
//  NCMenuViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCMenuViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIViewController* menuViewController;
@property (nonatomic, strong) IBOutlet UIViewController* contentViewController;

@end
