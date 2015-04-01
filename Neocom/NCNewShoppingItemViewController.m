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
#import "NCShoppingGroup+Neocom.h"

@interface NCNewShoppingItemViewController()
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSArray* contents;
@property (nonatomic, strong) NCShoppingList* shoppingList;
@property (nonatomic, strong) NSString* shoppingListName;
@property (nonatomic, assign) double totalPrice;
@property (nonatomic, assign) double totalContentsPrice;

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

- (IBAction)onAdd:(id)sender {
	NCShoppingList* shoppingList = self.shoppingList;
	[shoppingList.managedObjectContext performBlock:^{
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingGroup"];
		request.predicate = [NSPredicate predicateWithFormat:@"shoppingList == %@ AND identifier == %@", shoppingList, self.shoppingGroup.identifier];
		request.fetchLimit = 1;
		NCShoppingGroup* group = [[shoppingList.managedObjectContext executeFetchRequest:request error:nil] lastObject];
		
		if (!group) {
			[self.shoppingList.managedObjectContext insertObject:self.shoppingGroup];
			for (NCShoppingItem* item in self.shoppingGroup.shoppingItems)
				[self.shoppingList.managedObjectContext insertObject:item];
			self.shoppingGroup.shoppingList = self.shoppingList;
		}
		else {
			if (group.immutable) {
				group.quantity += self.shoppingGroup.quantity;
			}
			else {
				NSMutableDictionary* items = [NSMutableDictionary new];
				for (NCShoppingItem* item in group.shoppingItems)
					items[@(item.typeID)] = item;
				for (NCShoppingItem* item in self.shoppingGroup.shoppingItems) {
					NCShoppingItem* item2 = items[@(item.typeID)];
					item2.quantity += item.quantity;
				}
			}
		}
		
		if ([shoppingList.managedObjectContext hasChanges])
			[shoppingList.managedObjectContext save:nil];
	}];
	[self performSegueWithIdentifier:@"Unwind" sender:nil];
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
		return self.contents.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%d records, %@", nil),
				(int) self.rows.count,
				[NSString shortStringWithFloat:self.totalPrice * self.stepper.value unit:@"ISK"]];
	else {
		int records = 0;
		for (NCShoppingGroup* group in self.contents)
			records += group.shoppingItems.count;

		return [NSString stringWithFormat:NSLocalizedString(@"Contents: %d records, %@", nil),
				records,
				[NSString shortStringWithFloat:self.totalContentsPrice unit:@"ISK"]];
	}
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
	if (indexPath.section == 0) {
		NCShoppingItem* item = self.rows[indexPath.row];
		cell.titleLabel.text = item.type.typeName;
		if (item.price)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d, cost %@", nil), item.quantity * (int32_t) self.stepper.value, [NSString shortStringWithFloat:item.price.sell.percentile * item.quantity * self.stepper.value unit:@"ISK"]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d", nil), item.quantity * (int32_t) self.stepper.value];
		cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.object = item.type;
	}
	else {
		NCShoppingGroup* group = self.contents[indexPath.row];
		cell.titleLabel.text = group.name;
		double price = group.price;
		if (price > 0)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d, cost %@", nil), group.quantity, [NSString shortStringWithFloat:price unit:@"ISK"]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty. %d", nil), group.quantity];
		cell.imageView.image = group.iconFile ? [NCDBEveIcon eveIconWithIconFile:group.iconFile] : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.object = group;
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
	__block NSMutableArray* rows;
	__block NSArray* shoppingGroups;
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
										   NCStorage* storage = [NCStorage sharedStorage];
										   [storage.backgroundManagedObjectContext performBlockAndWait:^{
											   rows = [[self.shoppingGroup.shoppingItems allObjects] mutableCopy];
											   [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
											   shoppingGroups = [self.shoppingList.shoppingGroups sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
											   
											   NSMutableArray* itemsWithoutPrice = [NSMutableArray new];
											   [itemsWithoutPrice addObjectsFromArray:[rows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"price == nil"]]];
											   for (NCShoppingGroup* group in shoppingGroups)
												   [itemsWithoutPrice addObjectsFromArray:[[group.shoppingItems allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"price == nil"]]];
											   
											   if (itemsWithoutPrice.count > 0) {
												   NCPriceManager* priceManager = [NCPriceManager sharedManager];
												   NSDictionary* prices = [priceManager pricesWithTypes:[itemsWithoutPrice valueForKey:@"typeID"]];
												   for (NCShoppingItem* item in itemsWithoutPrice)
													   item.price = prices[@(item.typeID)];
											   }
										   }];
									   }
						   completionHandler:^(NCTask *task) {
							   if (![task isCancelled]) {
								   self.rows = rows;
								   self.contents = shoppingGroups;
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
	__block double totalPrice = 0;
	__block double totalContentsPrice = 0;
	
	NCStorage* storage = [NCStorage sharedStorage];
	[storage.managedObjectContext performBlockAndWait:^{
		for (NCShoppingItem* item in self.rows)
			totalPrice += item.quantity * item.price.sell.percentile;
		for (NCShoppingGroup* group in self.contents)
			totalContentsPrice += group.price;
	}];

	self.totalPrice = totalPrice;
	self.totalContentsPrice = totalContentsPrice;
}

@end
