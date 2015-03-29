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

@interface NCNewShoppingItemViewController()
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSArray* shoppingListItems;
@property (nonatomic, strong) NCShoppingList* shoppingList;
@property (nonatomic, strong) NSString* shoppingListName;
@property (nonatomic, assign) NSInteger itemsCount;
@property (nonatomic, assign) double totalPrice;

- (void) reload;
- (void) reloadSummary;
@end

@implementation NCNewShoppingItemViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.shoppingList = [NCShoppingList currentShoppingList];
	if (self.shoppingList)
		[self reload];
}

- (IBAction)onChangeQuantity:(id)sender {
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return self.rows.count;
	else if (section == 1)
		return 1;
	else
		return self.shoppingListItems.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ items costs %@", nil),
				[NSString shortStringWithFloat:self.itemsCount * self.stepper.value unit:nil],
				[NSString shortStringWithFloat:self.totalPrice * self.stepper.value unit:@"ISK"]];
	else if (section == 1)
		return NSLocalizedString(@"Shopping list", nil);
	else
		return NSLocalizedString(@"Contents", nil);
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
	if (indexPath.section == 1) {
		cell.titleLabel.text = self.shoppingListName;
		cell.subtitleLabel.text = nil;
		cell.imageView.image = nil;
	}
	else {
		NCShoppingItem* item = indexPath.section == 0 ? self.rows[indexPath.row] : self.shoppingListItems[indexPath.row];
		cell.titleLabel.text = item.type.typeName;
		if (item.price)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d, Cost %@", nil), item.quantity * (int32_t) self.stepper.value, [NSString shortStringWithFloat:item.price.sell.percentile * item.quantity * self.stepper.value unit:@"ISK"]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d", nil), item.quantity * (int32_t) self.stepper.value];
		cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.object = item.type;
	}
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.section == 1)
		return @"ShoppingListCell";
	else
		return @"TypeCell";
}

#pragma mark - Private

- (void) reload {
	__block NSMutableArray* rows;
	__block NSArray* items;
	self.stepper.enabled = NO;

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
						   }];
}

- (void) reloadSummary {
	NSInteger itemsCount = 0;
	double totalPrice = 0;

	for (NCShoppingItem* item in self.rows) {
		totalPrice += item.quantity * item.price.sell.percentile;
		itemsCount += item.quantity;
	}
	self.itemsCount = itemsCount;
	self.totalPrice = totalPrice;
}

@end
