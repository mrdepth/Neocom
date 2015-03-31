//
//  NCNewShoppingItemViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 28.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCNewShoppingItemViewController.h"
#import "NCShoppingList.h"
#import "NCShoppingItem+Neocom.h"
#import "NCPriceManager.h"
#import "NSString+Neocom.h"
#import "UIAlertView+Block.h"

@interface NCNewShoppingItemViewController()
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSArray* shoppingListItems;
@property (nonatomic, strong) NCShoppingList* shoppingList;
@property (nonatomic, strong) NSString* shoppingListName;
@property (nonatomic, assign) double totalPrice;

- (void) reload;
- (void) reloadSummary;
@end

@implementation NCNewShoppingItemViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	self.shoppingList = [NCShoppingList currentShoppingList];
	if (self.shoppingList)
		[self reload];
}

- (IBAction)onChangeQuantity:(id)sender {
	[self.quantityItem setTitle:[NSString stringWithFormat:@"%.0f", self.stepper.value]];
	[self.tableView reloadData];
}

- (IBAction)onSetQuantity:(id)sender {
	UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Enter Quantity", nil)
													 message:nil
										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										   otherButtonTitles:@[NSLocalizedString(@"Ok", nil)]
											 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
												 if (selectedButtonIndex != alertView.cancelButtonIndex) {
													 UITextField* textField = [alertView textFieldAtIndex:0];
													 int32_t quantity = [textField.text intValue];
													 quantity = MIN(self.stepper.maximumValue, MAX(self.stepper.minimumValue, quantity));
													 self.stepper.value = quantity;
													 [self.quantityItem setTitle:[NSString stringWithFormat:@"%.0f", self.stepper.value]];
													 [self.tableView reloadData];
												 }
											 }
												 cancelBlock:nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField* textField = [alertView textFieldAtIndex:0];
	textField.keyboardType = UIKeyboardTypeDecimalPad;
	textField.text = [NSString stringWithFormat:@"%.0f", self.stepper.value];
	[alertView show];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:NO animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Navigation

- (IBAction)unwindFromShoppingListsManager:(UIStoryboardSegue*) segue {
	self.shoppingList = [NCShoppingList currentShoppingList];
	[self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return self.rows.count;
	else
		return self.shoppingListItems.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%d records costs %@", nil),
				(int) self.rows.count,
//				(int) self.stepper.value,
				[NSString shortStringWithFloat:self.totalPrice * self.stepper.value unit:@"ISK"]];
	else
		return NSLocalizedString(@"Shopping list", nil);
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 0) {
		[self.rows removeObjectAtIndex:indexPath.row];
		//[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self reloadSummary];
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCShoppingItem* item = indexPath.section == 0 ? self.rows[indexPath.row] : self.shoppingListItems[indexPath.row];
	cell.titleLabel.text = item.type.typeName;
	if (item.price)
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d, Cost %@", nil), item.quantity * (int32_t) self.stepper.value, [NSString shortStringWithFloat:item.price.sell.percentile * item.quantity * self.stepper.value unit:@"ISK"]];
	else
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d", nil), item.quantity * (int32_t) self.stepper.value];
	cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = item.type;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) didChangeStorage {
	[self reload];
}

#pragma mark - Private

- (void) reload {
	__block NSMutableArray* rows;
	__block NSArray* items;
	self.stepper.enabled = NO;
	
	if (self.shoppingList) {
		[self.shoppingList.managedObjectContext performBlock:^{
			NSString* name = self.shoppingList.name;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.navigationItem.rightBarButtonItem.title = name;
			});
		}];
	}

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
									   title:NCTaskManagerDefaultTitle
									   block:^(NCTask *task) {
										   rows = [self.items mutableCopy];
										   [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
										   
										   items = [self.shoppingList.items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
										   
										   NSMutableArray* itemsWithoutPrice = [NSMutableArray new];
										   [itemsWithoutPrice addObjectsFromArray:[rows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"price == nil"]]];
										   [itemsWithoutPrice addObjectsFromArray:[items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"price == nil"]]];
										   if (itemsWithoutPrice.count > 0) {
											   NCPriceManager* priceManager = [NCPriceManager sharedManager];
											   NSDictionary* prices = [priceManager pricesWithTypes:[itemsWithoutPrice valueForKey:@"typeID"]];
											   for (NCShoppingItem* item in itemsWithoutPrice)
												   item.price = prices[@(item.typeID)];
										   }
									   }
						   completionHandler:^(NCTask *task) {
							   if (![task isCancelled]) {
								   self.rows = rows;
								   self.items = items;
								   [self reloadSummary];
								   [self.shoppingList.managedObjectContext performBlockAndWait:^{
									   self.shoppingListName = self.shoppingList.name;
								   }];
								   if (!self.shoppingListName)
									   self.shoppingListName = NSLocalizedString(@"Default", nil);
								   [self.tableView reloadData];
								   self.stepper.enabled = YES;
							   }
						   }];
}

- (void) reloadSummary {
	double totalPrice = 0;

	for (NCShoppingItem* item in self.rows)
		totalPrice += item.quantity * item.price.sell.percentile;
	self.totalPrice = totalPrice;
}

@end
