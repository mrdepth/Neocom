//
//  NCFittingCharacterPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterPickerViewController.h"
#import "UIViewController+Neocom.h"

@interface NCFittingCharacterPickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCFitCharacter* character);

@end

@implementation NCFittingCharacterPickerViewController

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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
}

- (void) presentInViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(NCFitCharacter* character)) completion {
	[[self.viewControllers[0] navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)]];
	
	self.completionHandler = completion;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[controller presentViewControllerInPopover:self fromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
	else
		[controller presentViewController:self animated:animated completion:nil];
}

@end
