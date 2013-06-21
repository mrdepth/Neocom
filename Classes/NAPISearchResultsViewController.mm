//
//  NAPISearchResultsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 19.06.13.
//
//

#import "NAPISearchResultsViewController.h"
#import "NAPISearchFitCellView.h"
#import "UITableViewCell+Nib.h"
#import "NeocomAPI.h"
#import "EUOperationQueue.h"
#import "UIAlertView+Error.h"
#import "EVEDBAPI.h"
#import "FittingViewController.h"
#import "CharacterEVE.h"
#import "EVEAccount.h"
#import "ShipFit.h"
#import "NSNumberFormatter+Neocom.h"

@interface NAPISearchResultsViewController ()
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) NSMutableDictionary* types;
- (void) reload;
@end

@implementation NAPISearchResultsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Community Fits", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background3.png"]];
		self.navigationItem.titleView = self.orderSegmentedControl;
	}
	else {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeOrder:(id)sender {
	[self reload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NAPISearchFitCellView";
    NAPISearchFitCellView *cell = (NAPISearchFitCellView*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [NAPISearchFitCellView cellWithNibName:@"NAPISearchFitCellView" bundle:nil reuseIdentifier:CellIdentifier];
 
	NAPISearchItem* item = self.rows[indexPath.row];
	EVEDBInvType* ship = self.types[@(item.typeID)];

	cell.titleLabel.text = ship.typeName;
	cell.iconImageView.image = [UIImage imageNamed:[ship typeSmallImageName]];
	
	if (item.flags & NeocomAPIFlagHybridTurrets)
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"Icons/icon13_06.png"];
	else if (item.flags & NeocomAPIFlagLaserTurrets)
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"Icons/icon13_10.png"];
	else if (item.flags & NeocomAPIFlagProjectileTurrets)
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"Icons/icon12_14.png"];
	else if (item.flags & NeocomAPIFlagMissileLaunchers)
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"Icons/icon04_01.png"];
	else
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"turrets.png"];
	
	NSString* tankType;
	if (item.flags & NeocomAPIFlagActiveTank) {
		if (item.flags & NeocomAPIFlagArmorTank) {
			cell.tankTypeImageView.image = [UIImage imageNamed:@"armorRepairer.png"];
			tankType = NSLocalizedString(@"Active Armor", nil);
		}
		else {
			cell.tankTypeImageView.image = [UIImage imageNamed:@"shieldBooster.png"];
			tankType = NSLocalizedString(@"Active Shield", nil);
		}
	}
	else {
		cell.tankTypeImageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
		tankType = NSLocalizedString(@"Passive", nil);
	}
	
	cell.ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ EHP, %@", nil),
						  [NSNumberFormatter neocomLocalizedStringFromInteger:item.ehp],
						  tankType];
	cell.turretDpsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil),
								[NSNumberFormatter neocomLocalizedStringFromInteger:item.turretDps]];
	cell.droneDpsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.droneDps]];
	cell.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Speed: %@ m/s", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.speed]];
	cell.maxRangeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Optimal: %@ m", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.maxRange]];
	cell.falloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Falloff: %@ m", nil),
							  [NSNumberFormatter neocomLocalizedStringFromInteger:item.falloff]];
	cell.capacitorLabel.text = item.flags & NeocomAPIFlagCapStable ? NSLocalizedString(@"Capacitor is Stable", nil) : NSLocalizedString(@"Capacitor is Unstable", nil);
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NAPISearchItem* item = self.rows[indexPath.row];
	
	FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
	__block NSError *error = nil;
	EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Loadout", nil)];
	__weak EUOperation* weakOperation = operation;
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	
	[operation addExecutionBlock:^{
		character = new eufe::Character(fittingViewController.fittingEngine);
		weakOperation.progress = 0.3;
		
		EVEAccount* currentAccount = [EVEAccount currentAccount];
		if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
			CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
			character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[eveCharacter skillsMap]);
		}
		else
			character->setCharacterName("All Skills 0");
		weakOperation.progress = 0.6;
		
		fit = [ShipFit shipFitWithCanonicalName:item.canonicalName character:character];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![weakOperation isCancelled] && fit && character) {
			if (error) {
				[[UIAlertView alertViewWithError:error] show];
			}
			else {
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.navigationController pushViewController:fittingViewController animated:YES];
			}
		}
		else {
			if (character)
				delete character;
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark - Private

- (void) reload {
	NSString* order;
	switch (self.orderSegmentedControl.selectedSegmentIndex) {
		case 0:
			order = @"dps";
			break;
		case 1:
			order = @"ehp";
			break;
		case 2:
			order = @"maxRange";
			break;
		case 3:
			order = @"falloff";
			break;
	}
	
	NSMutableArray* rowsTmp = [NSMutableArray array];
	NSMutableDictionary* typesTmp = [NSMutableDictionary dictionary];
	
	__block NSError* error = nil;
	EUOperation *operation = [EUOperation operationWithIdentifier:@"NAPISearchResultsViewController+reload" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NAPISearch* search = [NAPISearch searchWithCriteria:self.criteria order:order error:&error progressHandler:nil];
		for (NAPISearchItem* item in search.loadouts) {
			NSNumber* key = @(item.typeID);
			if (!typesTmp[key]) {
				EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
				if (type)
					typesTmp[key] = type;
			}
		}
		
		[rowsTmp addObjectsFromArray:search.loadouts];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			if (error) {
				[[UIAlertView alertViewWithError:error] show];
			}
			else {
				self.rows = rowsTmp;
				self.types = typesTmp;
				[self.tableView reloadData];
			}
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void)viewDidUnload {
	[self setOrderSegmentedControl:nil];
	[super viewDidUnload];
}

@end
