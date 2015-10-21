//
//  NCNewShoppingItemViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 28.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCNewShoppingItemViewController.h"
#import "NCShoppingList.h"
#import "NCShoppingItem.h"
#import "NCShoppingGroup.h"
//#import "NCShoppingItem+Neocom.h"
#import "NCPriceManager.h"
#import "NSString+Neocom.h"
//#import "NCShoppingGroup+Neocom.h"
#import "UIViewController+Neocom.h"

@interface NCNewShoppingItemViewControllerItem : NSObject
@property (nonatomic, strong) NCShoppingItem* shoppingItem;
//@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, assign) double price;
@property (nonatomic, readonly) double cost;
@end

@interface NCNewShoppingItemViewControllerGroup : NSObject
@property (nonatomic, strong) NCShoppingGroup* shoppingGroup;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, assign) double price;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, readonly) double cost;
@end

@implementation NCNewShoppingItemViewControllerItem

- (double) cost {
	return self.price * self.shoppingItem.quantity;
}

@end

@implementation NCNewShoppingItemViewControllerGroup

- (double) cost {
	return [[self.items valueForKeyPath:@"@sum.cost"] doubleValue] * self.shoppingGroup.quantity;
}

@end

@interface NCNewShoppingItemViewController()
@property (nonatomic, strong) NSArray* shoppingGroups;
@property (nonatomic, strong) NSMutableArray* shoppingItems;
@property (nonatomic, strong) NCShoppingList* shoppingList;
@property (nonatomic, assign) double totalPrice;
@property (nonatomic, assign) double totalContentsPrice;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

- (void) reload;
- (void) reloadSummary;
@end

@implementation NCNewShoppingItemViewController

- (void) viewDidLoad {
	[super viewDidLoad];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
	self.refreshControl = nil;
	
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	
	NCShoppingList* shoppingList = [self.storageManagedObjectContext currentShoppingList];
	self.shoppingList = shoppingList;
	if (self.shoppingList)
		[self reload];
}

- (IBAction)onChangeQuantity:(id)sender {
	[self.quantityItem setTitle:[NSString stringWithFormat:@"%.0f", self.stepper.value]];
	[self.tableView reloadData];
}

- (IBAction)onSetQuantity:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Quantity", nil)
																		message:nil
																 preferredStyle:UIAlertControllerStyleAlert];
	__block UITextField* quantityTextField;
	[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		quantityTextField = textField;
		textField.keyboardType = UIKeyboardTypeDecimalPad;
		textField.text = [NSString stringWithFormat:@"%.0f", self.stepper.value];
		textField.clearButtonMode = UITextFieldViewModeAlways;
	}];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		int32_t quantity = [quantityTextField.text intValue];
		quantity = MIN(self.stepper.maximumValue, MAX(self.stepper.minimumValue, quantity));
		self.stepper.value = quantity;
		[self.quantityItem setTitle:[NSString stringWithFormat:@"%.0f", self.stepper.value]];
		[self.tableView reloadData];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)onAdd:(id)sender {
	NCShoppingList* shoppingList = self.shoppingList;
	int quantity = self.stepper.value;
	
	self.shoppingGroup.identifier = [self.shoppingGroup defaultIdentifier];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingGroup"];
	request.predicate = [NSPredicate predicateWithFormat:@"shoppingList == %@ AND identifier == %@", shoppingList, self.shoppingGroup.identifier];
	request.fetchLimit = 1;
	NCShoppingGroup* group = [[shoppingList.managedObjectContext executeFetchRequest:request error:nil] lastObject];
	
	if (!group) {
		[self.shoppingList.managedObjectContext insertObject:self.shoppingGroup];
		for (NCShoppingItem* item in self.shoppingGroup.shoppingItems)
			[self.shoppingList.managedObjectContext insertObject:item];
		self.shoppingGroup.shoppingList = self.shoppingList;
		self.shoppingGroup.quantity = quantity;
	}
	else {
		if (group.immutable) {
			group.quantity += quantity;
		}
		else {
			NSMutableDictionary* items = [NSMutableDictionary new];
			for (NCShoppingItem* item in group.shoppingItems)
				items[@(item.typeID)] = item;
			for (NCShoppingItem* item in self.shoppingGroup.shoppingItems) {
				NCShoppingItem* item2 = items[@(item.typeID)];
				if (item2)
					item2.quantity += item.quantity * quantity;
				else {
					[item.shoppingGroup removeShoppingItemsObject:item];
					[group.managedObjectContext insertObject:item];
					item.shoppingGroup = group;
					item.quantity *= quantity;
				}
			}
		}
	}
	
	if ([shoppingList.managedObjectContext hasChanges])
		[shoppingList.managedObjectContext save:nil];
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		//[self dismissViewControllerAnimated:YES completion:nil];
//	else
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
	NCShoppingList* shoppingList = [self.storageManagedObjectContext currentShoppingList];
	
	self.shoppingList = shoppingList;
	if (self.shoppingList)
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
		return self.shoppingItems.count;
	else
		return self.shoppingGroups.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		if (self.shoppingItems.count > 1)
			return [NSString stringWithFormat:NSLocalizedString(@"x%d, %d items, %@", nil),
					(int) self.stepper.value,
					(int) self.shoppingItems.count,
					[NSString shortStringWithFloat:self.totalPrice * self.stepper.value unit:@"ISK"]];
		else
			return [NSString stringWithFormat:NSLocalizedString(@"x%d, %@", nil),
					(int) self.stepper.value,
					[NSString shortStringWithFloat:self.totalPrice * self.stepper.value unit:@"ISK"]];

	}
	else {
		int records = [[self.shoppingGroups valueForKeyPath:@"@sum.items.@count"] intValue];
		return [NSString stringWithFormat:NSLocalizedString(@"Contents: %d items, %@", nil),
				records,
				[NSString shortStringWithFloat:self.totalContentsPrice unit:@"ISK"]];
	}
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 0) {
		[self.shoppingGroup removeShoppingItemsObject:[self.shoppingItems[indexPath.row] shoppingItem]];
		[self.shoppingItems removeObjectAtIndex:indexPath.row];
		[self reloadSummary];
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
	if (self.shoppingItems.count == 0)
		[self performSegueWithIdentifier:@"Unwind" sender:nil];
}

#pragma mark - Table View Delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section == 0) {
		NCNewShoppingItemViewControllerItem* item = self.shoppingItems[indexPath.row];
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.shoppingItem.typeID];
		cell.titleLabel.text = type.typeName;
		if (item.price)
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"x%d, %@", nil), item.shoppingItem.quantity * (int32_t) self.stepper.value, [NSString shortStringWithFloat:item.price * item.shoppingItem.quantity * self.stepper.value unit:@"ISK"]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"x%d", nil), item.shoppingItem.quantity * (int32_t) self.stepper.value];
		cell.iconView.image = type.icon.image.image ?: self.defaultTypeIcon.image.image;
		cell.object = type;
	}
	else {
		NCNewShoppingItemViewControllerGroup* group = self.shoppingGroups[indexPath.row];
		cell.titleLabel.text = group.shoppingGroup.name;
		double price = group.price;
		NSMutableString* s = [NSMutableString new];
		if (group.shoppingGroup.immutable)
			[s appendFormat:NSLocalizedString(@"x%d, %d items", nil), group.shoppingGroup.quantity, group.items.count];
		else
			[s appendFormat:NSLocalizedString(@"%d items", nil), group.items.count];
		
		if (price > 0)
			[s appendFormat:NSLocalizedString(@", %@", nil), [NSString shortStringWithFloat:price unit:@"ISK"]];
		
		cell.subtitleLabel.text = s;
		cell.iconView.image = group.icon ? group.icon.image.image : self.defaultTypeIcon.image.image;
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
	self.title = self.shoppingGroup.name;
	self.navigationItem.rightBarButtonItem.title = self.shoppingList.name;

	NSMutableDictionary* types = [NSMutableDictionary new];
	
	NSMutableArray* allItems = [NSMutableArray new];
	
	NSArray* (^loadShoppingGroup)(NCShoppingGroup*) = ^ (NCShoppingGroup* group){
		NSMutableArray* items = [NSMutableArray new];
		for (NCShoppingItem* item in group.shoppingItems) {
			NCNewShoppingItemViewControllerItem* row = [NCNewShoppingItemViewControllerItem new];
			row.shoppingItem = item;
			NCDBInvType* type = types[@(item.typeID)];
			if (!type) {
				type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				if (type)
					types[@(item.typeID)] = type;
			}
			
//			row.type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
			[items addObject:row];
			[allItems addObject:row];
		}
		return items;
	};
	
	NSArray* shoppingItems = loadShoppingGroup(self.shoppingGroup);
	
	NSMutableArray* shoppingGroups = [NSMutableArray new];
	NSArray* groups = [self.shoppingList.shoppingGroups sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	for (NCShoppingGroup* shoppingGroup in groups) {
		NCNewShoppingItemViewControllerGroup* group = [NCNewShoppingItemViewControllerGroup new];
		group.shoppingGroup = shoppingGroup;
		group.items = loadShoppingGroup(shoppingGroup);
		if (shoppingGroup.iconFile)
			group.icon = [self.databaseManagedObjectContext eveIconWithIconFile:shoppingGroup.iconFile];
		[shoppingGroups addObject:group];
	}

	self.stepper.enabled = NO;
	[[NCPriceManager sharedManager] requestPricesWithTypes:[allItems valueForKeyPath:@"shoppingItem.typeID"] completionBlock:^(NSDictionary *prices) {
		for (NCNewShoppingItemViewControllerItem* item in allItems) {
			item.price = [prices[@(item.shoppingItem.typeID)] doubleValue];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			self.shoppingGroups = shoppingGroups;
			self.shoppingItems = [shoppingItems mutableCopy];
			self.stepper.enabled = YES;
			[self reloadSummary];
			[self.tableView reloadData];
		});
	}];
}

- (void) reloadSummary {
	self.totalPrice = [[self.shoppingItems valueForKeyPath:@"@sum.cost"] doubleValue];
	self.totalContentsPrice = [[self.shoppingGroups valueForKeyPath:@"@sum.cost"] doubleValue];
}

@end
