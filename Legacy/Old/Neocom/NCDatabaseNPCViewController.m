//
//  NCDatabaseNPCViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseNPCViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseNPCViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@property (nonatomic, strong) NSFetchedResultsController* searchResult;
@property (nonatomic, strong) NCDBEveIcon* defaultGroupIcon;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
- (void) reload;
@end

@implementation NCDatabaseNPCViewController

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
	self.defaultGroupIcon = [self.databaseManagedObjectContext defaultGroupIcon];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

	self.refreshControl = nil;
    
	[self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id row = [sender object];
	if ([segue.identifier isEqualToString:@"NCDatabaseNPCViewController"]) {
		NCDatabaseNPCViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.npcGroup = row;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [row objectID];
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	return self.npcGroup.managedObjectContext ?: [super databaseManagedObjectContext];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView && !self.searchContentsController ? self.result.sections[section] : self.searchResult.sections[section];
	return sectionInfo.numberOfObjects;
}

#pragma mark - NCTableViewController

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
	
	request.predicate = [NSPredicate predicateWithFormat:@"group.category.categoryID == 11 AND typeName CONTAINS[C] %@", searchString];
	
	request.fetchBatchSize = 50;
	self.searchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
	[self.searchResult performFetch:nil];
	
	[(NCDatabaseNPCViewController*) self.searchController.searchResultsController setResult:self.searchResult];
	completionBlock();
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView && !self.searchContentsController  ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	if ([row isKindOfClass:[NCDBInvType class]])
		return @"TypeCell";
	else
		return @"NpcGroupCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = tableView == self.tableView && !self.searchContentsController ? self.result.sections[indexPath.section] : self.searchResult.sections[indexPath.section];
	id row = sectionInfo.objects[indexPath.row];
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	if ([row isKindOfClass:[NCDBInvType class]]) {
		NCDBInvType* type = row;
		cell.titleLabel.text = type.typeName;
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.object = row;
	}
	else {
		NCDBNpcGroup* npcGroup = row;
		cell.titleLabel.text = npcGroup.npcGroupName;
		
		cell.iconView.image = npcGroup.icon ? npcGroup.icon.image.image : self.defaultGroupIcon.image.image;
		cell.object = row;
	}
}

#pragma mark - Private

- (void) reload {
	if (self.npcGroup) {
		if (self.npcGroup.group) {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"group == %@", self.npcGroup.group];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
			[self.result performFetch:nil];
		}
		else {
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"NpcGroup"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"npcGroupName" ascending:YES]];
			request.predicate = [NSPredicate predicateWithFormat:@"parentNpcGroup == %@", self.npcGroup];
			self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
			[self.result performFetch:nil];
		}
	}
	else {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"NpcGroup"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"npcGroupName" ascending:YES]];
		request.predicate = [NSPredicate predicateWithFormat:@"parentNpcGroup == NULL"];
		self.result = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.databaseManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
		[self.result performFetch:nil];
	}
}

@end
