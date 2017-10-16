//
//  NCKillMailDetailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMailDetailsViewController.h"
#import "UIImageView+URL.h"
#import "NCKillMail.h"
#import "UIColor+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCTableViewCell.h"
#import "NCKillMailDetailsAttackerCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingShipViewController.h"

@interface NCKillMailDetailsViewControllerSection: NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCKillMailDetailsViewControllerSection
@end

@interface NCKillMailDetailsViewController ()
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, strong) NSArray* attackers;
@end

@implementation NCKillMailDetailsViewController

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
	self.tableView.tableHeaderView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];

	self.characterNameLabel.text = self.killMail.victim.characterName;
	self.corporationNameLabel.text = self.killMail.victim.corporationName;
	self.allianceNameLabel.text = self.killMail.victim.allianceName;
	
	[self.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:self.killMail.victim.characterID size:EVEImageSizeRetina64 error:nil]];

	if (self.killMail.victim.corporationID)
		[self.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:self.killMail.victim.corporationID size:EVEImageSizeRetina32 error:nil]];
	if (self.killMail.victim.allianceID)
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:self.killMail.victim.allianceID size:EVEImageSizeRetina32 error:nil]];

	NCDBMapSolarSystem* solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:self.killMail.solarSystemID];
	if (solarSystem) {
		NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.security];
		NSString* s = [NSString stringWithFormat:@"%@ %@", ss, solarSystem.solarSystemName];
		NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
		[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.security] range:NSMakeRange(0, ss.length)];
		self.locationLabel.attributedText = title;
	}
	else {
		self.locationLabel.attributedText = nil;
		self.locationLabel.text = NSLocalizedString(@"Unknown Location", nil);
	}
	
	NSDateFormatter* dateFormatter = [NSDateFormatter new];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.dateLabel.text = [dateFormatter stringFromDate:self.killMail.killTime];
	self.damageTakenLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Damage taken: %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.killMail.victim.damageTaken]];
	
	NCDBInvType* shipType = [self.databaseManagedObjectContext invTypeWithTypeID:self.killMail.victim.shipTypeID];
	if (shipType) {
		self.typeImageView.image = shipType.icon.image.image ?: [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
		self.shipLabel.text = shipType.typeName;
	}
	else {
		self.typeImageView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"74_14"] image] image];
		self.shipLabel.text = NSLocalizedString(@"Unknown Ship Type", nil);
	}
	
	
	NSMutableArray* sections = [NSMutableArray new];
	NSString* titles[] = {
		NSLocalizedString(@"High power slots", nil),
		NSLocalizedString(@"Medium power slots", nil),
		NSLocalizedString(@"Low power slots", nil),
		NSLocalizedString(@"Rig power slots", nil),
		NSLocalizedString(@"Sub system slots", nil),
		NSLocalizedString(@"Drone bay", nil),
		NSLocalizedString(@"Cargo", nil)};
	NSArray* arrays[] = {self.killMail.hiSlots, self.killMail.medSlots, self.killMail.lowSlots, self.killMail.rigSlots, self.killMail.subsystemSlots, self.killMail.droneBay, self.killMail.cargo};
	for (int i = 0; i < 7; i++) {
		NSArray* array = arrays[i];
		if (array.count > 0) {
			NCKillMailDetailsViewControllerSection* section = [NCKillMailDetailsViewControllerSection new];
			section.title = titles[i];
			section.rows = array;
			[sections addObject:section];
		}
	}
	self.items = sections;
	
	NSMutableArray* finalBlow = [NSMutableArray new];
	NSMutableArray* attackers = [NSMutableArray new];
	for (NCKillMailAttacker* attacker in self.killMail.attackers) {
		if (attacker.finalBlow)
			[finalBlow addObject:attacker];
		else
			[attackers addObject:attacker];
	}
	
	sections = [NSMutableArray new];
	if (finalBlow.count > 0) {
		NCKillMailDetailsViewControllerSection* section = [NCKillMailDetailsViewControllerSection new];
		section.rows = finalBlow;
		section.title = NSLocalizedString(@"Final blow", nil);
		[sections addObject:section];
	}
	if (attackers.count > 0) {
		NCKillMailDetailsViewControllerSection* section = [NCKillMailDetailsViewControllerSection new];
		section.rows = attackers;
		section.title = NSLocalizedString(@"Top damage", nil);
		[sections addObject:section];
	}
	self.attackers = sections;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	[self.tableView reloadData];
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
	else if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = [[NCShipFit alloc] initWithKillMail:self.killMail];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.segmentedControl.selectedSegmentIndex == 0 ? self.items.count : self.attackers.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCKillMailDetailsViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.items[sectionIndex] : self.attackers[sectionIndex];
	return section.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCKillMailDetailsViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.items[sectionIndex] : self.attackers[sectionIndex];
	return section.title;
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.segmentedControl.selectedSegmentIndex == 0)
		return @"Cell";
	else
		return @"NCKillMailDetailsAttackerCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (self.segmentedControl.selectedSegmentIndex == 0) {
		NCKillMailDetailsViewControllerSection* section = self.items[indexPath.section];
		NCKillMailItem* row = section.rows[indexPath.row];
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
		cell.object = type;
		cell.iconView.image = type.icon.image.image ?: [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
		cell.titleLabel.text = type.typeName;
		if (row.destroyed) {
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ destroyed", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.qty]];
			cell.titleLabel.textColor = [UIColor redColor];
		}
		else {
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ dropped", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.qty]];
			cell.titleLabel.textColor = [UIColor greenColor];
		}
	}
	else {
		NCKillMailDetailsViewControllerSection* section = self.attackers[indexPath.section];
		NCKillMailAttacker* row = section.rows[indexPath.row];
		NCKillMailDetailsAttackerCell* cell = (NCKillMailDetailsAttackerCell*) tableViewCell;
		cell.object = row;
		
		cell.characterNameLabel.text = row.characterName;
		cell.corporationNameLabel.text = row.corporationName;
		cell.allianceNameLabel.text = row.allianceName;
		
		[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:row.characterID size:EVEImageSizeRetina64 error:nil]];
		
		if (row.corporationID)
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:row.corporationID size:EVEImageSizeRetina32 error:nil]];
		if (row.allianceID)
			[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:row.allianceID size:EVEImageSizeRetina32 error:nil]];
		
		NCDBInvType* shipType = [self.databaseManagedObjectContext invTypeWithTypeID:row.shipTypeID];
		if (shipType) {
			cell.shipTypeImageView.image = shipType.icon.image.image ?: [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
			cell.shipLabel.text = shipType.typeName;
		}
		else {
			cell.shipTypeImageView.image = nil;
			cell.shipLabel.text = nil;
		}
		

		NCDBInvType* weaponType = [self.databaseManagedObjectContext invTypeWithTypeID:row.weaponTypeID];
		if (weaponType) {
			cell.weaponTypeImageView.image = weaponType.icon.image.image ?: [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
			cell.damageDoneLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ damage done with %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.damageDone], weaponType.typeName];
		}
		else {
			cell.weaponTypeImageView.image = nil;
			cell.damageDoneLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ damage done", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:row.damageDone]];
		}
	}
}

@end
