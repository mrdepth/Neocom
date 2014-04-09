//
//  NCStarbasesDetailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCStarbasesDetailsViewController.h"
#import "EVEStarbaseListItem+Neocom.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSArray+Neocom.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCStarbasesDetailsViewControllerDataRow : NSObject
@property (nonatomic, strong) EVEDBInvControlTowerResource* resource;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, strong) NSString* remains;
@property (nonatomic, strong) UIColor* color;
@end


@interface NCStarbasesDetailsViewControllerDataSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) EVEDBInvControlTowerResourcePurpose* purpose;
@end

@implementation NCStarbasesDetailsViewControllerDataRow
@end

@implementation NCStarbasesDetailsViewControllerDataSection
@end

@interface NCStarbasesDetailsViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCStarbasesDetailsViewController

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
	
	float hours = [[self.starbase.details serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:self.starbase.details.currentTime] / 3600.0;
	if (hours < 0)
		hours = 0;
	float bonus = self.starbase.resourceConsumptionBonus;
	
	float security = 1.0;
	if (self.starbase.solarSystem)
		security = self.starbase.solarSystem.security;
	else if (self.starbase.moon)
		security = self.starbase.moon.security;
	
	NSMutableArray* rows = [NSMutableArray new];
	for (EVEDBInvControlTowerResource *resource in [self.starbase.type resources]) {
		
		if ((resource.minSecurityLevel > 0 && security < resource.minSecurityLevel) ||
			(resource.factionID > 0 && self.starbase.solarSystem.region.factionID != resource.factionID))
			continue;
		
		int quantity = 0;
		for (EVEStarbaseDetailFuelItem *item in self.starbase.details.fuel) {
			if (item.typeID == resource.resourceTypeID) {
				quantity = item.quantity - hours * round(resource.quantity * bonus);
				break;
			}
		}
		NSTimeInterval remainsTime = quantity / round(resource.quantity * bonus) * 3600;
		NSString* remains = nil;
		UIColor* color = nil;
		if (quantity > 0) {
			if (remainsTime > 3600 * 24)
				color = [UIColor greenColor];
			else if (remainsTime > 3600)
				color = [UIColor yellowColor];
			else
				color = [UIColor redColor];
			remains = [NSString stringWithTimeLeft:remainsTime];
		}
		else {
			color = [UIColor redColor];
			remains = @"0s";
		}
		
		NSString *consumption;
		if (resource.purposeID == 2 || resource.purposeID == 3)
			consumption = NSLocalizedString(@"n/a", nil);
		else
			consumption = [NSString stringWithFormat:NSLocalizedString(@"%@/h", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:round(resource.quantity * bonus)]];
		NCStarbasesDetailsViewControllerDataRow* row = [NCStarbasesDetailsViewControllerDataRow new];
		row.resource = resource;
		row.quantity = quantity;
		row.remains = [NSString stringWithFormat:@"%@, %@", remains, consumption];
		//row.consumption = consumption;
		row.color = color;
		[rows addObject:row];
	}
	
	[rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"resource.resourceType.typeName" ascending:YES]]];
	NSMutableArray* sections = [NSMutableArray new];
	for (NSArray* array in [rows arrayGroupedByKey:@"resource.purposeID"]) {
		NCStarbasesDetailsViewControllerDataSection* section = [NCStarbasesDetailsViewControllerDataSection new];
		section.rows = array;
		section.purpose = [[array[0] resource] purpose];
		[sections addObject:section];
	}
	[sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"purpose.purposeID" ascending:YES]]];
	self.sections = sections;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections[section] rows] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCStarbasesDetailsViewControllerDataSection* section = self.sections[sectionIndex];
	return section.purpose.purposeText;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCStarbasesDetailsViewControllerDataSection* section = self.sections[indexPath.section];
	NCStarbasesDetailsViewControllerDataRow* row = section.rows[indexPath.row];
	
	NCTableViewCell* cell = (NCTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
	cell.iconView.image = [UIImage imageNamed:row.resource.resourceType.typeSmallImageName];
	cell.titleLabel.text = row.resource.resourceType.typeName;
	
	cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ left (%@)", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.quantity], row.remains];
	cell.detailTextLabel.textColor = row.color;
	cell.object = row.resource.resourceType;
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
