//
//  NCDatabaseTypePickerContentViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypePickerContentViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCDgmppItemShipCell.h"
#import "NCDgmppItemModuleCell.h"
#import "NCDgmppItemChargeCell.h"

@interface NCDatabaseTypePickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCDBInvType* type);
@property (nonatomic, strong) NCDBDgmppItemCategory* category;

@end

@interface NCDatabaseTypePickerContentViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NCDBEveIcon* defaultGroupIcon;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

@end

@implementation NCDatabaseTypePickerContentViewController

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
	self.refreshControl = nil;
	
	if (self.group) {
		self.title = self.group.groupName;
	}

	self.defaultGroupIcon = [self.databaseManagedObjectContext defaultGroupIcon];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

}

- (void) dealloc {
	//[self.searchDisplayController.searchBar removeFromSuperview]; //Avoid crash
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.result)
		[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypePickerContentViewController"]) {
		NCDatabaseTypePickerContentViewController* destinationViewController = segue.destinationViewController;
		NCDBDgmppItemGroup* group = [sender object];
		destinationViewController.group = group;
		
		destinationViewController.title = group.groupName;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		NCDBDgmppItem* item = [sender object];
		controller.typeID = [item.type objectID];
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.group.managedObjectContext ?: [super databaseManagedObjectContext];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.result.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.numberOfObjects;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];

	if ([row isKindOfClass:[NCDBDgmppItem class]]) {
		NCDBDgmppItem* item = row;
		NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
		navigationController.completionHandler(item.type);
	}
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NCTableViewController

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	if (searchString.length > 1) {
		NCDatabaseTypePickerViewController* navigationController = (NCDatabaseTypePickerViewController*) self.navigationController;
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmppItem"];
		request.sortDescriptors = @[
									[NSSortDescriptor sortDescriptorWithKey:@"type.metaGroup.metaGroupID" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.metaLevel" ascending:YES],
									[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
		
		request.predicate = [NSPredicate predicateWithFormat:@"ANY groups.category == %@ AND type.typeName CONTAINS[C] %@", navigationController.category, searchString];
		
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"type.metaGroupName" cacheName:nil];
		NSError* error = nil;
		[self.searchResult performFetch:&error];
	}
	else {
		self.searchResult = nil;
	}
	
	[(NCDatabaseTypePickerContentViewController*) self.searchController.searchResultsController setResult:self.searchResult];
	completionBlock();
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	
	if ([row isKindOfClass:[NCDBDgmppItem class]]) {
		NCDBDgmppItem* item = row;
		if (item.shipResources)
			return @"NCDgmppItemShipCell";
		else if (item.requirements)
			return item.requirements.calibration > 0 ? @"NCDgmppItemRigCell" : @"NCDgmppItemModuleCell";
		else if (item.damage)
			return @"NCDgmppItemChargeCell";
		else
			return @"TypeCell";
	}
	else
		return @"MarketGroupCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	
	if ([row isKindOfClass:[NCDBDgmppItem class]]) {
		NCDBDgmppItem* item = row;
		NSMutableAttributedString* typeName = [[NSMutableAttributedString alloc] initWithString:item.type.typeName ?: NSLocalizedString(@"Unknown", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
		if (item.type.metaLevel > 0)
			[typeName appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %d", item.type.metaLevel] attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor], NSFontAttributeName:[UIFont systemFontOfSize:8]}]];
		UIImage* image = item.type.icon.image.image ?: self.defaultTypeIcon.image.image;

		if (item.shipResources) {
			NCDgmppItemShipCell* cell = (NCDgmppItemShipCell*) tableViewCell;
			cell.typeImageView.image = image;
			cell.typeNameLabel.attributedText = typeName;
			cell.hiSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.hiSlots];
			cell.medSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.medSlots];
			cell.lowSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.lowSlots];
			cell.rigSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.rigSlots];
			cell.turretsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.turrets];
			cell.launchersLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.launchers];
			cell.object = row;
		}
		else if (item.requirements) {
			NCDgmppItemModuleCell* cell = (NCDgmppItemModuleCell*) tableViewCell;
			cell.typeImageView.image = image;
			cell.typeNameLabel.attributedText = typeName;
			cell.powerGridLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.powerGrid];
			cell.cpuLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.cpu];
			cell.calibrationLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.calibration];
			cell.object = row;
		}
		else if (item.damage) {
			NCDgmppItemChargeCell* cell = (NCDgmppItemChargeCell*) tableViewCell;
			cell.typeImageView.image = image;
			cell.typeNameLabel.attributedText = typeName;
			float damage = item.damage.emAmount + item.damage.thermalAmount + item.damage.kineticAmount + item.damage.explosiveAmount;
			
			cell.emLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.emAmount];
			cell.emLabel.progress = item.damage.emAmount / damage;

			cell.kineticLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.kineticAmount];
			cell.kineticLabel.progress = item.damage.kineticAmount / damage;

			cell.thermalLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.thermalAmount];
			cell.thermalLabel.progress = item.damage.thermalAmount / damage;

			cell.explosiveLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.explosiveAmount];
			cell.explosiveLabel.progress = item.damage.explosiveAmount / damage;
			
			cell.damageLabel.text = [NSString stringWithFormat:@"%.1f", damage];
			
			cell.object = row;
		}
		else {
			NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
			cell.titleLabel.attributedText = typeName;
			cell.iconView.image = image;
			cell.object = row;
		}
	}
	else {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		if ([row isKindOfClass:[NCDBDgmppItemGroup class]]) {
			NCDBDgmppItemGroup* group = row;
			cell.titleLabel.text = group.groupName;
			cell.iconView.image = group.icon.image.image;
		}
		
		if (!cell.iconView.image)
			cell.iconView.image = self.defaultGroupIcon.image.image;
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
	NSFetchRequest* request;
	request = [NSFetchRequest fetchRequestWithEntityName:@"DgmppItem"];
	request.sortDescriptors = @[
								[NSSortDescriptor sortDescriptorWithKey:@"type.metaGroup.metaGroupID" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.metaLevel" ascending:YES],
								[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]];
	
	request.predicate = [NSPredicate predicateWithFormat:@"ANY groups == %@", self.group];
	
	self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"type.metaGroupName" cacheName:nil];
	[self.result performFetch:nil];

	if (self.result.fetchedObjects.count == 0) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmppItemGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == %@", self.group];
		
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:nil];
	}
	[self.tableView reloadData];
}

@end
