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
@property (nonatomic, strong) NCDBInvControlTowerResource* resource;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, strong) NSString* remains;
@property (nonatomic, strong) UIColor* color;
@end


@interface NCStarbasesDetailsViewControllerDataSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NCDBInvControlTowerResourcePurpose* purpose;
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
	for (NCDBInvControlTowerResource *resource in self.starbase.type.controlTower.resources) {
		if ((resource.minSecurityLevel > 0 && security < resource.minSecurityLevel) ||
			(resource.factionID > 0 && self.starbase.solarSystem.constellation.region.factionID != resource.factionID))
			continue;
		
		int quantity = 0;
		for (EVEStarbaseDetailFuelItem *item in self.starbase.details.fuel) {
			if (item.typeID == resource.resourceType.typeID) {
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
		if (resource.purpose.purposeID == 2 || resource.purpose.purposeID == 3)
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
	for (NSArray* array in [rows arrayGroupedByKey:@"resource.purpose.purposeID"]) {
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

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCStarbasesDetailsViewControllerDataSection* section = self.sections[indexPath.section];
	NCStarbasesDetailsViewControllerDataRow* row = section.rows[indexPath.row];
	
	NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
	
	cell.iconView.image = row.resource.resourceType.icon ? row.resource.resourceType.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.titleLabel.text = row.resource.resourceType.typeName;
	
	cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ left (%@)", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.quantity], row.remains];
	cell.detailTextLabel.textColor = row.color;
	cell.object = row.resource.resourceType;
}

@end
