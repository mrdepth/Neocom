//
//  NCSkillsContainerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillsContainerViewController.h"
#import "NCSkillQueueViewController.h"
#import "NCSkillsViewController.h"

@interface NCSkillsContainerViewController ()
@property (nonatomic, weak) NCSkillQueueViewController* skillQueueViewController;
@property (nonatomic, weak) NCSkillsViewController* skillsViewController;
@end

@implementation NCSkillsContainerViewController

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
	for (id controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCSkillQueueViewController class]])
			self.skillQueueViewController = controller;
		else if ([controller isKindOfClass:[NCSkillsViewController class]])
			self.skillsViewController = controller;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItems:@[self.skillQueueViewController.editButtonItem,
													  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self.skillQueueViewController action:@selector(onAction:)]]
										   animated:YES];
	else {
		self.navigationItem.rightBarButtonItems = self.skillQueueViewController.navigationItem.rightBarButtonItems;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.skillsViewController.tableView.contentInset = self.skillQueueViewController.tableView.contentInset;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
