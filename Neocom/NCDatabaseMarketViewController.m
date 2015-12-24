//
//  NCDatabaseMarketViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 18.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseMarketViewController.h"
#import "NCDatabaseTypeMarketInfoViewController.h"
#import "NCDatabaseTypeCRESTMarketInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseMarketViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NCDBEveIcon* defaultGroupIcon;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

- (void) reload;
@end

@implementation NCDatabaseMarketViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;

	if (self.marketGroup) {
		self.title = self.marketGroup.marketGroupName;
	}

	self.defaultGroupIcon = [self.databaseManagedObjectContext defaultGroupIcon];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

	
	
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseMarketViewController"]) {
		NCDatabaseMarketViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.marketGroup = row;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeMarketInfoViewController"]) {
		NCDatabaseTypeMarketInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.typeID = [row objectID];
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeCRESTMarketInfoViewController"]) {
		NCDatabaseTypeCRESTMarketInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.typeID = [row objectID];
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.marketGroup.managedObjectContext ?: [super databaseManagedObjectContext];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return tableView == self.tableView ? self.result.sections.count : self.searchResult.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.name.length > 0 ? sectionInfo.name : nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsUseCRESTMarketProviderKey]) {
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:@"CREST Market API" message:NSLocalizedString(@"Do you wish to use CREST Market API? CREST Market API allows you to load realtime ingame market orders. You can change it later in the settings.", nil) preferredStyle:UIAlertControllerStyleAlert];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Use CREST API", NO) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NCSettingsUseCRESTMarketProviderKey];
			[self performSegueWithIdentifier:@"NCDatabaseTypeCRESTMarketInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Left as is", NO) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NCSettingsUseCRESTMarketProviderKey];
			[self performSegueWithIdentifier:@"NCDatabaseTypeMarketInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		}]];
		[self presentViewController:controller animated:YES completion:nil];
	}
	else {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCRESTMarketProviderKey])
			[self performSegueWithIdentifier:@"NCDatabaseTypeCRESTMarketInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
		else
			[self performSegueWithIdentifier:@"NCDatabaseTypeMarketInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	if (searchString.length >= 2) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"marketGroup <> NULL AND published == TRUE AND typeName CONTAINS[C] %@", searchString];
		
		request.fetchBatchSize = 50;
		self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];

		NSError* error = nil;
		[self.searchResult performFetch:&error];
	}
	else {
		self.searchResult = nil;
	}
    
	[(NCDatabaseMarketViewController*) self.searchController.searchResultsController setResult:self.searchResult];
	completionBlock();
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	if ([row isKindOfClass:[NCDBInvType class]])
		return @"TypeCell";
	else
		return @"MarketGroupCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];

	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	if ([row isKindOfClass:[NCDBInvType class]]) {
		NCDBInvType* type = row;
		cell.titleLabel.text = type.typeName;
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.object = row;
	}
	else {
		if ([row isKindOfClass:[NCDBInvCategory class]]) {
			NCDBInvCategory* category = row;
			cell.titleLabel.text = category.categoryName;
			cell.iconView.image = category.icon.image.image;
		}
		else {
			NCDBInvMarketGroup* marketGroup = row;
			cell.titleLabel.text = marketGroup.marketGroupName;
			cell.iconView.image = marketGroup.icon.image.image;
		}
		
		cell.object = row;
	}
	
	if (!cell.iconView.image)
		cell.iconView.image = self.defaultTypeIcon.image.image;
}

#pragma mark - Private

- (void) reload {
	NSError* error = nil;

	if (self.marketGroup) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvMarketGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == %@", self.marketGroup];
		
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:&error];
		if (self.result.fetchedObjects.count == 0) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[
										[NSSortDescriptor sortDescriptorWithKey:@"metaGroup.metaGroupID" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"metaLevel" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"marketGroup == %@ AND published == TRUE", self.marketGroup];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:@"metaGroupName" cacheName:nil];
			[self.result performFetch:&error];
		}
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvMarketGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:&error];
	}
}

@end
