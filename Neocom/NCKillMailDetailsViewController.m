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

@interface NCKillMailDetailsViewController ()

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
	
	self.characterNameLabel.text = self.killMail.victim.characterName;
	self.corporationNameLabel.text = self.killMail.victim.corporationName;
	self.allianceNameLabel.text = self.killMail.victim.allianceName;
	
	[self.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:self.killMail.victim.characterID size:EVEImageSizeRetina64 error:nil]];

	if (self.killMail.victim.corporationID)
		[self.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:self.killMail.victim.corporationID size:EVEImageSizeRetina32 error:nil]];
	if (self.killMail.victim.allianceID)
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:self.killMail.victim.allianceID size:EVEImageSizeRetina32 error:nil]];

	self.locationLabel.text = self.killMail.solarSystem.solarSystemName;

	if (self.killMail.solarSystem) {
		NSString* ss = [NSString stringWithFormat:@"%.1f", self.killMail.solarSystem.security];
		NSString* s = [NSString stringWithFormat:@"%@ %@", ss, self.killMail.solarSystem.solarSystemName];
		NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
		[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:self.killMail.solarSystem.security] range:NSMakeRange(0, ss.length)];
		self.locationLabel.attributedText = title;
	}
	else {
		self.locationLabel.attributedText = nil;
		self.locationLabel.text = NSLocalizedString(@"Unknown Location", nil);
	}
	
	NSDateFormatter* dateFormatter = [NSDateFormatter new];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	self.dateLabel.text = [dateFormatter stringFromDate:self.killMail.killTime];
	self.damageTakenLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Damage taken: %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.killMail.victim.damageTaken]];
	
	if (self.killMail.victim.shipType) {
		self.typeImageView.image = [UIImage imageNamed:self.killMail.victim.shipType.typeSmallImageName];
		self.shipLabel.text = self.killMail.victim.shipType.typeName;
	}
	else {
		self.typeImageView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		self.shipLabel.text = NSLocalizedString(@"Unknown Ship Type", nil);
	}

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	[self.tableView reloadData];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
