//
//  NCFittingPOSWorkspaceViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSWorkspaceViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewHeaderView.h"
#import "UIColor+Neocom.h"

@interface NCFittingPOSWorkspaceViewController ()
@property (nonatomic, assign) BOOL needsReload;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, strong) NSArray* sectionIdentifiers;
- (void) internalReload;
@end

@implementation NCFittingPOSWorkspaceViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHeaderView"];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self updateVisibility];
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
			[self internalReload];
	}];
}

- (void) reloadWithCompletionBlock:(void(^)()) completionBlock {
	completionBlock();
}

- (NCFittingPOSViewController*) controller {
	return (NCFittingPOSViewController*) self.parentViewController;
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.controller.databaseManagedObjectContext;
}

- (UIImage*) defaultTypeImage {
	if (!_defaultTypeImage)
		_defaultTypeImage = [self.databaseManagedObjectContext defaultTypeIcon].image.image;
	return _defaultTypeImage;
}

- (void) updateVisibility {
	if (self.needsReload && self.isVisible) {
		[self internalReload];
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

- (void) internalReload {
	NSInteger n = [self numberOfSectionsInTableView:self.tableView];
	NSMutableArray* sectionIdentifiers = [NSMutableArray new];
	for (NSInteger i = 0; i < n; i++) {
		id identifier = [self identifierForSection:i];
		[sectionIdentifiers addObject:identifier ?: @(i)];
	}
	
	if (!self.sectionIdentifiers) {
		self.sectionIdentifiers = sectionIdentifiers;
		[self.tableView reloadData];
	}
	else {
		[self.tableView beginUpdates];
		NSMutableIndexSet* deleteSections = [NSMutableIndexSet new];
		NSMutableIndexSet* insertSections = [NSMutableIndexSet new];
		NSMutableIndexSet* reloadSections = [NSMutableIndexSet new];
		
		NSInteger sectionIndex = 0;
		for (id identifier in self.sectionIdentifiers) {
			if (![sectionIdentifiers containsObject:identifier])
				[deleteSections addIndex:sectionIndex];
			else
				[reloadSections addIndex:sectionIndex];
			sectionIndex++;
		}
		
		sectionIndex = 0;
		for (id identifier in sectionIdentifiers) {
			if (![self.sectionIdentifiers containsObject:identifier])
				[insertSections addIndex:sectionIndex];
			sectionIndex++;
		}
		
		self.sectionIdentifiers = sectionIdentifiers;
		if (deleteSections.count > 0)
			[self.tableView deleteSections:deleteSections withRowAnimation:UITableViewRowAnimationFade];
		if (insertSections.count > 0)
			[self.tableView insertSections:insertSections withRowAnimation:UITableViewRowAnimationFade];
		if (reloadSections.count > 0)
			[self.tableView reloadSections:reloadSections withRowAnimation:UITableViewRowAnimationFade];
		
		[self.tableView endUpdates];
	}
}

@end
