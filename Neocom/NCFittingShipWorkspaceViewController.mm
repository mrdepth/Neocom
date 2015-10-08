//
//  NCFittingShipWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipWorkspaceViewController.h"
#import "NCTableViewHeaderView.h"
#import "UIColor+Neocom.h"
#import "NCFittingShipViewController.h"

@interface NCFittingShipWorkspaceViewController ()
@property (nonatomic, assign) BOOL needsReload;
@property (nonatomic, readonly) BOOL isVisible;
@end

@implementation NCFittingShipWorkspaceViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self updateVisibility];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.refreshControl = nil;
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHeaderView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) reload {
	[self reloadWithCompletionBlock:^{
		self.needsReload = !self.isVisible;
		if (self.isVisible)
			[self.tableView reloadData];
	}];
}

- (void) reloadWithCompletionBlock:(void(^)()) completionBlock {
	completionBlock();
}

- (NCFittingShipViewController*) controller {
	return (NCFittingShipViewController*) self.parentViewController;
}

- (NCTaskManager*) taskManager {
	return [self.controller taskManager];
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.controller.databaseManagedObjectContext;
}

- (UIImage*) defaultTypeImage {
	if (!_defaultTypeImage)
		_defaultTypeImage = [self.databaseManagedObjectContext defaultTypeIcon].image.image;
	return _defaultTypeImage;
}

- (UIImage*) targetImage {
	if (!_targetImage)
		_targetImage = [self.databaseManagedObjectContext eveIconWithIconFile:@"04_12"].image.image;
	return _targetImage;
}

- (void) updateVisibility {
	if (self.needsReload && self.isVisible) {
		[self.tableView reloadData];
		self.needsReload = NO;
	}
}

#pragma mark - Private

- (BOOL) isVisible {
	if (!self.view.window)
		return NO;
	CGRect rect = [self.view.window convertRect:self.view.bounds fromCoordinateSpace:self.view];
	return CGRectIntersectsRect(rect, self.view.window.frame);
}

@end
