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
#import "NCShoppingGroup.h"

@interface NCShoppingListsManagerViewController()
@property (nonatomic, strong) NSMutableArray* rows;

- (void) reload;
- (void) unwind;

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
		[self.rows removeObjectAtIndex:indexPath.row];

		[list.managedObjectContext deleteObject:list];
		if (list == [self.storageManagedObjectContext currentShoppingList]) {
			if (self.rows.count > 0)
				[NCShoppingList setCurrentShoppingList:self.rows[0][@"object"]];
			else
				[NCShoppingList setCurrentShoppingList:nil];
		}
		[self.storageManagedObjectContext save:nil];
		[self.delegate shoppingListsManagerViewController:self didSelectShoppingList:[self.storageManagedObjectContext currentShoppingList]];

		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"New Shopping List", nil)
																			message:nil
																	 preferredStyle:UIAlertControllerStyleAlert];
		__block UITextField* nameTextField;
		[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			nameTextField = textField;
			textField.clearButtonMode = UITextFieldViewModeAlways;
		}];
		
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Create", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSString* name = nameTextField.text.length > 0 ? nameTextField.text : NSLocalizedString(@"Unnamed", nil);
			
			NCShoppingList* shoppingList = [[NCShoppingList alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingList" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
			shoppingList.name = name;
			[self.storageManagedObjectContext save:nil];
			[NCShoppingList setCurrentShoppingList:shoppingList];
			[self.delegate shoppingListsManagerViewController:self didSelectShoppingList:[self.storageManagedObjectContext currentShoppingList]];
			[self unwind];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		
		[self presentViewController:controller animated:YES completion:nil];
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
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename Shopping List", nil)
																				message:nil
																		 preferredStyle:UIAlertControllerStyleAlert];
			__block UITextField* nameTextField;
			[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
				nameTextField = textField;
				textField.text = row[@"name"];
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSString* name = nameTextField.text.length > 0 ? nameTextField.text : NSLocalizedString(@"Unnamed", nil);
				
				shoppingList.name = name;
				[self.storageManagedObjectContext save:nil];
				[self.rows replaceObjectAtIndex:indexPath.row withObject:@{@"name":name, @"object":shoppingList}];
				[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			
			[self presentViewController:controller animated:YES completion:nil];
		}
		else {
			[NCShoppingList setCurrentShoppingList:shoppingList];
			[self.delegate shoppingListsManagerViewController:self didSelectShoppingList:[self.storageManagedObjectContext currentShoppingList]];
			[self unwind];
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
		if (cell.object == [self.storageManagedObjectContext currentShoppingList])
			accessoryImage = [UIImage imageNamed:@"checkmark"];
		cell.accessoryView = accessoryImage ? [[UIImageView alloc] initWithImage:accessoryImage] : nil;
		cell.iconView.image = [UIImage imageNamed:@"note"];
	}
	else {
		cell.titleLabel.text = NSLocalizedString(@"Add Shopping List", nil);
		cell.subtitleLabel.text = nil;
		cell.object = nil;
		cell.accessoryView = nil;
		cell.iconView.image = [UIImage imageNamed:@"note"];
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
	for (NCShoppingList* shoppingList in [self.storageManagedObjectContext allShoppingLists]) {
		NSInteger records = 0;
		for (NCShoppingGroup* group in shoppingList.shoppingGroups)
			records += group.shoppingItems.count;
		if (shoppingList.name)
			[rows addObject:@{@"object":shoppingList, @"records":@(records), @"name":shoppingList.name}];
		else
			[rows addObject:@{@"object":shoppingList, @"records":@(records)}];
	}
	self.rows = rows;
	[self.tableView reloadData];
}

- (void) unwind {
	[self performSegueWithIdentifier:@"Unwind" sender:nil];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (self.navigationController.viewControllers[0] == self)
			[self dismissViewControllerAnimated:YES completion:nil];
	}

}

@end
