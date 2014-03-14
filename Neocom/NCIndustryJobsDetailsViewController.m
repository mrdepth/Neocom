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
@property (nonatomic, strong) NSString* imageName;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) id object;

- (id) initWithTitle:(NSString*) title desciption:(NSString*) description imageName:(NSString*) imageName imageURL:(NSURL*) url;
@end

@implementation NCIndustryJobsDetailsViewControllerRow

- (id) initWithTitle:(NSString*) title desciption:(NSString*) description imageName:(NSString*) imageName imageURL:(NSURL*) url {
	if (self = [super init]) {
		self.title = title;
		self.description = description;
		self.imageName = imageName;
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
																			imageName:nil
																			 imageURL:nil]];
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"State", nil)
																	   desciption:[self.job localizedStateWithCurrentDate:self.currentDate]
																		imageName:nil
																		 imageURL:nil]];
	
	
	if (self.job.installedItemType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Input", nil)
																										 desciption:self.job.installedItemType.typeName
																										  imageName:self.job.installedItemType.typeSmallImageName
																										   imageURL:nil];
		row.object = self.job.installedItemType;
		[rows addObject:row];
	}
	if (self.job.outputType) {
		NCIndustryJobsDetailsViewControllerRow* row = [[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Output", nil)
																										 desciption:self.job.outputType.typeName
																										  imageName:self.job.outputType.typeSmallImageName
																										   imageURL:nil];
		row.object = self.job.outputType;
		[rows addObject:row];
	}
	
	if (self.job.installedItemLocation)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Installed Location", nil)
																		   desciption:self.job.installedItemLocation.name
																			imageName:nil
																			 imageURL:nil]];
	if (self.job.outputLocation)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Output Location", nil)
																		   desciption:self.job.outputLocation.name
																			imageName:nil
																			 imageURL:nil]];
	
	if (self.job.installerName)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Installed by", nil)
																		   desciption:self.job.installerName
																			imageName:nil
																			 imageURL:[EVEImage characterPortraitURLWithCharacterID:(int32_t) self.job.installerID size:EVEImageSizeRetina32 error:nil]]];
	
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Runs", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.runs]
																		imageName:nil
																		 imageURL:nil]];
	
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Productivity Level", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.installedItemProductivityLevel]
																		imageName:nil
																		 imageURL:nil]];
	[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Material Level", nil)
																	   desciption:[NSNumberFormatter neocomLocalizedStringFromInteger:self.job.installedItemMaterialLevel]
																		imageName:nil
																		 imageURL:nil]];
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	
	if (self.job.installTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Install Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.installTime]
																			imageName:nil
																			 imageURL:nil]];
	if (self.job.beginProductionTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"Begin Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.beginProductionTime]
																			imageName:nil
																			 imageURL:nil]];
	if (self.job.endProductionTime)
		[rows addObject:[[NCIndustryJobsDetailsViewControllerRow alloc] initWithTitle:NSLocalizedString(@"End Production Time", nil)
																		   desciption:[dateFormatter stringFromDate:self.job.endProductionTime]
																			imageName:nil
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
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = [sender object];
	}
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
	if (row.object) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	}

	cell.object = row.object;
	cell.textLabel.text = row.title;
	cell.detailTextLabel.text = row.description;
	if (row.imageName)
		cell.imageView.image = [UIImage imageNamed:row.imageName];
	else
		cell.imageView.image = nil;
	if (row.imageURL)
		[cell.imageView setImageWithContentsOfURL:row.imageURL];
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
