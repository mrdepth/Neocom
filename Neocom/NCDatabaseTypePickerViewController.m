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
		
		NCDatabase* database = [NCDatabase sharedDatabase];
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItemGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"category == %@ AND parentGroup == NULL", category];
		request.fetchLimit = 1;
		NSArray* result = [database.managedObjectContext executeFetchRequest:request error:nil];
		
		NCDatabaseTypePickerContentViewController* contentViewController = self.viewControllers[0];
		contentViewController.group = result.count == 1 ? result[0] : nil;
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
//		[controller.splitViewController.viewControllers[0] showViewController:self sender:view];
	}
}


- (void) setTitle:(NSString *)title {
	[super setTitle:title];
	if (self.viewControllers.count > 0)
		[self.viewControllers[0] setTitle:self.title];
}


@end
