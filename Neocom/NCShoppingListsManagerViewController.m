//
//  NCShoppingListsManagerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 30.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingListsManagerViewController.h"
#import "NCShoppingList.h"
#import "NCStorage.h"
#import "UIAlertView+Block.h"

@interface NCShoppingListsManagerViewController()
@property (nonatomic, strong) NSMutableArray* rows;

- (void) reload;

@end

@implementation NCShoppingListsManagerViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self reload];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	BOOL changed = editing != self.editing;
	[super setEditing:editing animated:animated];

	if (changed) {
		if (editing)
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.rows.count inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
		else
			[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.rows.count inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.rows.count + (self.editing ? 1 : 0);
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.rows removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row < self.rows.count ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleInsert;
}

#pragma mark - Tale view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.rows.count)
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	else {
		UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"New Shopping List", nil)
														 message:nil
											   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											   otherButtonTitles:@[NSLocalizedString(@"Done", nil)]
												 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
													 if (selectedButtonIndex != alertView.cancelButtonIndex) {
														 UITextField* textField = [alertView textFieldAtIndex:0];
														 
													 }
												 }
													 cancelBlock:nil];
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView show];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row < self.rows.count) {
		NSDictionary* row = self.rows[indexPath.row];
		NSString* name = row[@"name"];
		cell.titleLabel.text = name ? name : NSLocalizedString(@"Default", nil);
		int records = [row[@"records"] intValue];
		cell.subtitleLabel.text =  records > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d records", nil), records] : NSLocalizedString(@"Empty", nil);
		cell.object = row[@"object"];
	}
	else {
		cell.titleLabel.text = NSLocalizedString(@"Add Shopping List", nil);
		cell.subtitleLabel.text = nil;
		cell.object = nil;
	}
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) didChangeStorage {
	[self reload];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* rows = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 for (NCShoppingList* shoppingList in [[NCStorage sharedStorage] allShoppingLists]) {
												 NSInteger records = shoppingList.items.count;
												 if (shoppingList.name)
													 [rows addObject:@{@"object":shoppingList, @"records":@(records), @"name":shoppingList.name}];
												 else
													 [rows addObject:@{@"object":shoppingList, @"records":@(records)}];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.rows = rows;
									 [self.tableView reloadData];
								 }
							 }];
}

@end
