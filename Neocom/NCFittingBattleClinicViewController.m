//
//  NCFittingBattleClinicViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingBattleClinicViewController.h"
#import "BattleClinicAPI.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCFittingBattleClinicSearchResultsViewController.h"

@interface NCFittingBattleClinicViewController ()
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) NSMutableSet* selectedTags;
@property (nonatomic, strong) NCDatabaseTypePickerViewController* typePickerViewController;

- (void) testInputData;
@end

@implementation NCFittingBattleClinicViewController

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
	if (!self.selectedTags)
		self.selectedTags = [NSMutableSet new];
	[self testInputData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingBattleClinicSearchResultsViewController"]) {
		NCFittingBattleClinicSearchResultsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = self.type;
		destinationViewController.tags = [[self.selectedTags allObjects] sortedArrayUsingSelector:@selector(compare:)];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSArray* tags = self.data;
	return tags ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* tags = self.data;
	return section == 0 ? 1 : tags.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.section == 0) {
		cell.accessoryView = nil;
		if (!self.type) {
			cell.textLabel.text = NSLocalizedString(@"Select Ship", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
		}
		else {
			cell.textLabel.text = self.type.typeName;
			cell.imageView.image = [UIImage imageNamed:[self.type typeSmallImageName]];
		}
	}
	else {
		NSArray* tags = self.data;
		NSString *tag = [tags objectAtIndex:indexPath.row];
		cell.textLabel.text = tag;
		cell.imageView.image = nil;
		cell.accessoryView = [self.selectedTags containsObject:tag] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1)
		return NSLocalizedString(@"Tags", nil);
	else
		return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		
		self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
		[self.typePickerViewController presentWithConditions:@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"]
											inViewController:self
													fromRect:cell.bounds
													  inView:cell
													animated:YES
										   completionHandler:^(EVEDBInvType *type) {
											   self.type = type;
											   [self testInputData];
											   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
											   [self dismissAnimated];
										   }];
	}
	else {
		NSArray* tags = self.data;
		NSString *tag = [tags objectAtIndex:indexPath.row];
		if ([self.selectedTags containsObject:tag])
			[self.selectedTags removeObject:tag];
		else
			[self.selectedTags addObject:tag];
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self testInputData];
	}
	return;
}


#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	__block NSArray* tags = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BCEveLoadoutsTags *loadoutsTags = [BCEveLoadoutsTags eveLoadoutsTagsWithAPIKey:NCBattleClinicAPIKey error:&error progressHandler:nil];
											 tags = loadoutsTags.tags;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:tags withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (NSString*) recordID {
	return NSStringFromClass(self.class);
}

- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60 * 24;
}

#pragma mark - Private

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (void) testInputData {
	self.navigationItem.rightBarButtonItem.enabled = self.type && self.selectedTags.count > 0;
}

@end
