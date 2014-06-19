//
//  NCDatabaseTypePickerViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypePickerViewController.h"
#import "UIViewController+Neocom.h"
#import <objc/runtime.h>
#import "NSString+MD5.h"
#import "NCDatabase.h"
#import "NCDatabaseTypePickerContentViewController.h"

@interface NCDatabaseTypePickerContentViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@end

@interface NCDatabaseTypePickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCDBInvType* type);
@property (nonatomic, strong) NCDBEufeItemCategory* category;

@end

@implementation NCDatabaseTypePickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
}

- (void) presentWithCategory:(NCDBEufeItemCategory*) category inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(NCDBInvType* type)) completion {
	if (![self.category isEqual:category]) {
		self.category = category;
		for (UIViewController* controller in self.viewControllers)
			if ([controller.searchDisplayController isActive])
				[controller.searchDisplayController setActive:NO animated:NO];
		
		if (self.viewControllers.count > 1)
			[self setViewControllers:@[[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerContentViewController"]] animated:NO];
		
		NCDatabaseTypePickerContentViewController* contentViewController = self.viewControllers[0];
		contentViewController.group = nil;
		contentViewController.result = nil;
		contentViewController.searchResult = nil;
	}
	[self.viewControllers[0] setTitle:self.title];
	
	self.completionHandler = completion;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[controller presentViewControllerInPopover:self fromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
	else {
		[[self.viewControllers[0] navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)]];
		[controller presentViewController:self animated:animated completion:nil];
	}
}


- (void) setTitle:(NSString *)title {
	[super setTitle:title];
	if (self.viewControllers.count > 0)
		[self.viewControllers[0] setTitle:self.title];
}


@end
