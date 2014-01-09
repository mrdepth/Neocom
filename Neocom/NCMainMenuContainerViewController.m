//
//  NCMainMenuContainerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuContainerViewController.h"
#import "UIView+Nib.h"
#import "NCNavigationCharacterButton.h"

@interface NCMainMenuContainerViewController ()

@end

@implementation NCMainMenuContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	UIView* buttonView = [NCNavigationCharacterButton viewWithNibName:@"NCNavigationCharacterButton" bundle:nil];
	
	UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - buttonView.frame.size.height, buttonView.frame.size.width, buttonView.frame.size.height)];
//	[button addSubview:buttonView];
	//[self.navigationController.navigationBar addSubview:button];
	[self.navigationController.navigationBar addSubview:buttonView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
