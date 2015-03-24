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
#import "UIAlertView+Error.h"

@interface NCFittingBattleClinicViewController ()
@property (nonatomic, strong) NCDBInvType* type;
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
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1)
		return NSLocalizedString(@"Tags", nil);
	else
		return nil;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
			return UITableViewAutomaticDimension;

		UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell layoutIfNeeded];
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	}
	else {
		return 37;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		
		self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
		[self.typePickerViewController presentWithCategory:[NCDBEufeItemCategory shipsCategory]
										  inViewController:self
												  fromRect:cell.bounds
													inView:cell
												  animated:YES
										 completionHandler:^(NCDBInvType *type) {
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
										 [[UIAlertView alertViewWithError:error] show];
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

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
    if (indexPath.section == 0) {
		cell.accessoryView = nil;
		if (!self.type) {
			cell.titleLabel.text = NSLocalizedString(@"Select Ship", nil);
			cell.iconView.image = [[[NCDBEveIcon eveIconWithIconFile:@"09_05"] image] image];;
		}
		else {
			cell.titleLabel.text = self.type.typeName;
			cell.iconView.image = self.type.icon ? self.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		}
	}
	else {
		NSArray* tags = self.data;
		NSString *tag = [tags objectAtIndex:indexPath.row];
		cell.titleLabel.text = tag;
		cell.imageView.image = nil;
		cell.accessoryView = [self.selectedTags containsObject:tag] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
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
