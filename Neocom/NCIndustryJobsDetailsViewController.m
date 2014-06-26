//
//  NCIndustryJobsDetailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCIndustryJobsDetailsViewController.h"
#import "EVEIndustryJobsItem+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCTableViewCell.h"
#import "UIImageView+URL.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCIndustryJobsDetailsViewControllerRow : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) id object;

- (id) initWithTitle:(NSString*) title desciption:(NSString*) description icon:(NCDBEveIcon*) icon imageURL:(NSURL*) url;
@end

@implementation NCIndustryJobsDetailsViewControllerRow

- (id) initWithTitle:(NSString*) title desciption:(NSString*) description icon:(NCDBEveIcon*) icon imageURL:(NSURL*) url {
	if (self = [super init]) {
		self.title = title;
		self.description = description;
		self.icon = icon;
		self.imageURL = url;
	}
	return self;
}

@end

@interface NCIndustryJobsDetailsViewController ()
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCIndustryJobsDetailsViewController

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
	NSMutableArray* rows = [NSMutableArray new];
	
	if (self.job.activity)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Activity", nil)
																		   desciption:self.job.activity.activityName
																				 icon:nil
																			 imageURL:nil]];
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"State", nil)
																	   desciption:[self.job localizedStateWithCurrentDate:self.currentDate]
																			 icon:nil
																		 imageURL:nil]];
	
	
	if (self.job.installedItemType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Input", nil)
																										 desciption:self.job.installedItemType.typeName
																											   icon:self.job.installedItemType.icon ? self.job.installedItemType.icon : [NCDBEveIcon defaultTypeIcon]
																										   imageURL:nil];
		row.object = self.job.installedItemType;
		[rows addObject:row];
	}
	if (self.job.outputType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Output", nil)
																										 desciption:self.job.outputType.typeName
																											   icon:self.job.installedItemType.icon ? self.job.installedItemType.icon : [NCDBEveIcon defaultTypeIcon]
																										   imageURL:nil];
		row.object = self.job.outputType;
		[rows addObject:row];
	}
	
	if (self.job.installedItemLocation)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Installed Location", nil)
																		   desciption:self.job.installedItemLocation.name
																				 icon:nil
																			 imageURL:nil]];
	if (self.job.outputLocation)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Output Location", nil)
																		   desciption:self.job.outputLocation.name
																				 icon:nil
																			 imageURL:nil]];
	
	if (self.job.installerName)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Installed by", nil)
																		   desciption:self.job.installerName
																				 icon:nil
																			 imageURL:[EVEImage characterPortraitURLWithCharacterID:(int32_t) self.job.installerID size:EVEImageSizeRetina32 error:nil]]];
	
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Runs", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.runs]
																			 icon:nil
																		 imageURL:nil]];
	
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Productivity Level", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.installedItemProductivityLevel]
																			 icon:nil
																		 imageURL:nil]];
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Material Level", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.installedItemMaterialLevel]
																			 icon:nil
																		 imageURL:nil]];
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	
	if (self.job.installTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Install Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.installTime]
																				 icon:nil
																			 imageURL:nil]];
	if (self.job.beginProductionTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Begin Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.beginProductionTime]
																				 icon:nil
																			 imageURL:nil]];
	if (self.job.endProductionTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"End Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.endProductionTime]
																				 icon:nil
																			 imageURL:nil]];
	
	self.rows = rows;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = [sender object];
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		return [sender object] != nil;
	}
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCIndustryJobsDetailsViewControllerRow* row = self.rows[indexPath.row];
	NCTableViewCell* cell;
	if (row.object)
		cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
	else
		cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	NCIndustryJobsDetailsViewControllerRow* row = self.rows[indexPath.row];
	NCTableViewCell* cell;
	if (row.object)
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"TypeCell"];
	else
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];

	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCIndustryJobsDetailsViewControllerRow* row = self.rows[indexPath.row];
	NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
	
	cell.object = row.object;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.description;
	cell.iconView.image = row.icon.image.image;
	if (row.imageURL)
		[cell.iconView setImageWithContentsOfURL:row.imageURL];
}

@end
