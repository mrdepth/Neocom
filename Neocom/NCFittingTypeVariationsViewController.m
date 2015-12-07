//
//  NCFittingTypeVariationsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingTypeVariationsViewController.h"
#import "NCEufeItemShipCell.h"
#import "NCEufeItemModuleCell.h"
#import "NCEufeItemChargeCell.h"

@interface NCDatabaseTypeVariationsViewController ()
@property (nonatomic, strong) NSFetchedResultsController* result;
@end

@interface NCFittingTypeVariationsViewController ()
@end

@implementation NCFittingTypeVariationsViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedType = [sender object];
	}
	else
		[super prepareForSegue:segue sender:sender];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	NCDBInvType* row = sectionInfo.objects[indexPath.row];
	NCDBEufeItem* item = row.eufeItem;
	if (item) {
		if (item.shipResources)
			return @"NCEufeItemShipCell";
		else if (item.requirements)
			return @"NCEufeItemModuleCell";
		else if (item.damage)
			return @"NCEufeItemChargeCell";
	}
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.result.sections[indexPath.section];
	NCDBInvType* row = sectionInfo.objects[indexPath.row];
	NCDBEufeItem* item = row.eufeItem;
	
	NSMutableAttributedString* typeName = [[NSMutableAttributedString alloc] initWithString:item.type.typeName ?: NSLocalizedString(@"Unknown", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
	if (item.type.metaLevel > 0)
		[typeName appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %d", item.type.metaLevel] attributes:@{NSForegroundColorAttributeName:[UIColor lightTextColor], NSFontAttributeName:[UIFont systemFontOfSize:8]}]];

	UIImage* image = item.type.icon.image.image ?: [self.databaseManagedObjectContext defaultTypeIcon].image.image;
	
	
	if (item.shipResources) {
		NCEufeItemShipCell* cell = (NCEufeItemShipCell*) tableViewCell;
		cell.typeImageView.image = image;
		cell.typeNameLabel.attributedText = typeName;
		cell.hiSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.hiSlots];
		cell.medSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.medSlots];
		cell.lowSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.lowSlots];
		cell.rigSlotsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.rigSlots];
		cell.turretsLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.turrets];
		cell.launchersLabel.text = [NSString stringWithFormat:@"%d", item.shipResources.launchers];
		cell.object = row;
	}
	else if (item.requirements) {
		NCEufeItemModuleCell* cell = (NCEufeItemModuleCell*) tableViewCell;
		cell.typeImageView.image = image;
		cell.typeNameLabel.attributedText = typeName;
		cell.powerGridLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.powerGrid];
		cell.cpuLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.cpu];
		cell.calibrationLabel.text = [NSString stringWithFormat:@"%.1f", item.requirements.calibration];
		cell.object = row;
	}
	else if (item.damage) {
		NCEufeItemChargeCell* cell = (NCEufeItemChargeCell*) tableViewCell;
		cell.typeImageView.image = image;
		cell.typeNameLabel.attributedText = typeName;
		float damage = item.damage.emAmount + item.damage.thermalAmount + item.damage.kineticAmount + item.damage.explosiveAmount;
		
		cell.emLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.emAmount];
		cell.emLabel.progress = item.damage.emAmount / damage;
		
		cell.kineticLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.kineticAmount];
		cell.kineticLabel.progress = item.damage.kineticAmount / damage;
		
		cell.thermalLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.thermalAmount];
		cell.thermalLabel.progress = item.damage.thermalAmount / damage;
		
		cell.explosiveLabel.text = [NSString stringWithFormat:@"%.1f", item.damage.explosiveAmount];
		cell.explosiveLabel.progress = item.damage.explosiveAmount / damage;
		
		cell.damageLabel.text = [NSString stringWithFormat:@"%.1f", damage];
		
		cell.object = row;
	}
	else {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.titleLabel.attributedText = typeName;
		cell.iconView.image = image;
		cell.object = row;
	}
}


@end
