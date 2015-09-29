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
#import "NSString+Neocom.h"

@interface NCIndustryJobsDetailsViewControllerRow : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) id object;

- (id) initWithTitle:(NSString*) title desciption:(NSString*) description icon:(NCDBEveIcon*) icon imageURL:(NSURL*) url;
@end

@implementation NCIndustryJobsDetailsViewControllerRow
@synthesize description = _description;

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
	
	NCDBRamActivity* activity = [self.databaseManagedObjectContext ramActivityWithActivityID:self.job.activityID];
	
	if (activity)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Activity", nil)
																		   desciption:activity.activityName
																				 icon:nil
																			 imageURL:nil]];
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"State", nil)
																	   desciption:[self.job localizedStateWithCurrentDate:self.currentDate]
																			 icon:nil
																		 imageURL:nil]];
	
	NCDBInvType* blueprintType = [self.databaseManagedObjectContext invTypeWithTypeID:self.job.blueprintTypeID];
	if (blueprintType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Input", nil)
																										 desciption:blueprintType.typeName
																											   icon:blueprintType.icon ?: [self.databaseManagedObjectContext defaultTypeIcon]
																										   imageURL:nil];
		row.object = blueprintType;
		[rows addObject:row];
		self.title = blueprintType.typeName;
	}
	
	NCDBInvType* productType = [self.databaseManagedObjectContext invTypeWithTypeID:self.job.productTypeID];
	if (productType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Output", nil)
																										 desciption:productType.typeName
																											   icon:productType.icon ?: [self.databaseManagedObjectContext defaultTypeIcon]
																										   imageURL:nil];
		row.object = productType;
		[rows addObject:row];
	}
	
	if (self.job.blueprintLocation)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Installed Location", nil)
																		   desciption:self.job.blueprintLocation.name
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
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];

	if (self.job.startDate && self.job.endDate) {
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Production Time", nil)
																		   desciption:[NSString stringWithTimeLeft:[self.job.endDate timeIntervalSinceDate:self.job.startDate]]
																				 icon:nil
																			 imageURL:nil]];
	}

	if (self.job.startDate)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Begin Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.startDate]
																				 icon:nil
																			 imageURL:nil]];
	if (self.job.endDate)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"End Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.endDate]
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
		
		controller.typeID = [[sender object] objectID];
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

// Customize the appearance of table view cells.
- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCIndustryJobsDetailsViewControllerRow* row = self.rows[indexPath.row];
	if (row.object)
		return @"TypeCell";
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCIndustryJobsDetailsViewControllerRow* row = self.rows[indexPath.row];
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	
	cell.object = row.object;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.description;
	cell.iconView.image = row.icon.image.image;
	if (row.imageURL)
		[cell.iconView setImageWithContentsOfURL:row.imageURL];
}

@end
