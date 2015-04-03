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
#import "NCShoppingGroup.h"

@interface NCShoppingListsManagerViewController()
@property (nonatomic, strong) NSMutableArray* rows;

- (void) reload;

@end

@implementation NCShoppingListsManagerViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.rows.count + 1;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCShoppingList* list = self.rows[indexPath.row][@"object"];
		[list.managedObjectContext performBlock:^{
			[list.managedObjectContext deleteObject:list];
			[list.managedObjectContext save:nil];
			if (list == [NCShoppingList currentShoppingList])
				[NCShoppingList setCurrentShoppingList:nil];
			
		}];
		[self.rows removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"New Shopping List", nil)
														 message:nil
											   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											   otherButtonTitles:@[NSLocalizedString(@"Create", nil)]
												 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
													 if (selectedButtonIndex != alertView.cancelButtonIndex) {
														 UITextField* textField = [alertView textFieldAtIndex:0];
														 NSString* name = textField.text.length > 0 ? textField.text : NSLocalizedString(@"Unnamed", nil);
														 
														 NCStorage* storage = [NCStorage sharedStorage];
														 NSManagedObjectContext* context = [storage managedObjectContext];
														 __block NCShoppingList* shoppingList;
														 [context performBlockAndWait:^{
															 shoppingList = [[NCShoppingList alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingList" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
															 shoppingList.name = name;
															 [context save:nil];
														 }];
														 [self.rows addObject:@{@"name":name, @"object":shoppingList}];
														 [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
													 }
												 }
													 cancelBlock:nil];
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField* textField = [alertView textFieldAtIndex:0];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		[alertView show];
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
		NSDictionary* row = self.rows[indexPath.row];
		NCShoppingList* shoppingList = row[@"object"];

		if (self.editing) {
			UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename Shopping List", nil)
															 message:nil
												   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												   otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
													 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
														 if (selectedButtonIndex != alertView.cancelButtonIndex) {
															 UITextField* textField = [alertView textFieldAtIndex:0];
															 NSString* name = textField.text.length > 0 ? textField.text : NSLocalizedString(@"Unnamed", nil);
															 
															 NCStorage* storage = [NCStorage sharedStorage];
															 NSManagedObjectContext* context = [storage managedObjectContext];
															 [context performBlockAndWait:^{
																 shoppingList.name = name;
																 [context save:nil];
															 }];
															 [self.rows replaceObjectAtIndex:indexPath.row withObject:@{@"name":name, @"object":shoppingList}];
															 [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
														 }
													 }
														 cancelBlock:nil];
			alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
			UITextField* textField = [alertView textFieldAtIndex:0];
			textField.clearButtonMode = UITextFieldViewModeWhileEditing;
			textField.text = row[@"name"];
			[alertView show];
		}
		else {
			[NCShoppingList setCurrentShoppingList:shoppingList];
			[self performSegueWithIdentifier:@"Unwind" sender:nil];
		}
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
		
		UIImage* accessoryImage = nil;
		if (cell.object == [NCShoppingList currentShoppingList])
			accessoryImage = [UIImage imageNamed:@"checkmark.png"];
		cell.accessoryView = accessoryImage ? [[UIImageView alloc] initWithImage:accessoryImage] : nil;
		cell.iconView.image = [UIImage imageNamed:@"folder.png"];
	}
	else {
		cell.titleLabel.text = NSLocalizedString(@"Add Shopping List", nil);
		cell.subtitleLabel.text = nil;
		cell.object = nil;
		cell.accessoryView = nil;
		cell.iconView.image = [UIImage imageNamed:@"folder.png"];
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
												 NSInteger records = 0;
												 for (NCShoppingGroup* group in shoppingList.shoppingGroups)
													 records += group.shoppingItems.count;
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
