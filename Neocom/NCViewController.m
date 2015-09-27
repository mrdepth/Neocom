//
//  NCViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 26.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"
#import "NCAdaptivePopoverSegue.h"
#import "NCDatabase.h"
#import "NCStorage.h"
#import "NCCache.h"

@interface NCViewController ()
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;

@end

@implementation NCViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.taskManager.active = YES;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.taskManager.active = NO;
}

- (void) willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	if (!parent)
		[self.taskManager cancelAllOperations];
}

- (NCTaskManager*) taskManager {
	if (!_taskManager)
		_taskManager = [[NCTaskManager alloc] initWithViewController:self];
	return _taskManager;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[NCAdaptivePopoverSegue class]]) {
        NCAdaptivePopoverSegue* popoverSegue = (NCAdaptivePopoverSegue*) segue;
        popoverSegue.sender = sender;
    }
}

- (NSManagedObjectContext*) storageManagedObjectContext {
	@synchronized (self) {
		if (!_storageManagedObjectContext)
			_storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
		return _storageManagedObjectContext;
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	@synchronized (self) {
		if (!_databaseManagedObjectContext)
			_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
		return _databaseManagedObjectContext;
	}
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	@synchronized (self) {
		if (!_cacheManagedObjectContext)
			_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
		return _cacheManagedObjectContext;
	}
}

@end
