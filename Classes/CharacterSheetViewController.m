//
//  CharacterSheetViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 31.08.13.
//
//

#import "CharacterSheetViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "appearance.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "EUOperationQueue.h"
#import "UIAlertView+Error.h"
#import "NSNumberFormatter+Neocom.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "UIImageView+URL.h"

@interface CharacterSheetViewController ()
@property (nonatomic, strong) NSMutableArray* sections;
- (void) reload;
@end

@implementation CharacterSheetViewController

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
	self.title = NSLocalizedString(@"Character Sheet", nil);
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	
	NSDictionary* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	cell.textLabel.text = row[@"title"];
	cell.detailTextLabel.text = row[@"value"];
	UIColor* color = row[@"color"];
	if (!color)
		color = [UIColor lightTextColor];
	cell.detailTextLabel.textColor = color;
    
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* sections = [NSMutableArray new];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"CharacterSheetViewController+reload" name:NSLocalizedString(@"Loading Character Sheet", nil)];
	EVEAccount* account = [EVEAccount currentAccount];
	
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		EVECharacterSheet* characterSheet = account.characterSheet;
		if (!characterSheet)
			return;
		
		NSError* error = nil;
		//EVECorporationSheet* corporationSheet = [EVECorporationSheet corporationSheetWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID corporationID:account.character.corporationID error:&error progressHandler:nil];
		
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
			[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];

			NSMutableArray* rows = [NSMutableArray new];
			NSDictionary* section = @{@"rows": rows, @"title": NSLocalizedString(@"Bloodline", nil)};
			
			NSMutableString* value = [NSMutableString stringWithString:characterSheet.corporationName];
			if (characterSheet.allianceName)
				[value appendFormat:@", %@", characterSheet.allianceName];
			
			[rows addObject:@{@"title": characterSheet.name, @"value": value}];

			[rows addObject:@{@"title": NSLocalizedString(@"Date of birth", nil), @"value": [dateFormatter stringFromDate:characterSheet.DoB]}];
			[rows addObject:@{@"title": NSLocalizedString(@"Race", nil), @"value": characterSheet.race}];
			[rows addObject:@{@"title": NSLocalizedString(@"Bloodline", nil), @"value": characterSheet.bloodLine}];
			[rows addObject:@{@"title": NSLocalizedString(@"Ancestry", nil), @"value": characterSheet.ancestry}];
			[sections addObject:section];
			
			rows = [NSMutableArray new];
			section = @{@"rows": rows, @"title": NSLocalizedString(@"Attributes", nil)};
			EVECharacterSheetAttributeEnhancer* charismaEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* intelligenceEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* memoryEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* perceptionEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* willpowerEnhancer = nil;
			
			for (EVECharacterSheetAttributeEnhancer *enhancer in characterSheet.attributeEnhancers) {
				switch (enhancer.attribute) {
					case EVECharacterAttributeCharisma:
						charismaEnhancer = enhancer;
						break;
					case EVECharacterAttributeIntelligence:
						intelligenceEnhancer = enhancer;
						break;
					case EVECharacterAttributeMemory:
						memoryEnhancer = enhancer;
						break;
					case EVECharacterAttributePerception:
						perceptionEnhancer = enhancer;
						break;
					case EVECharacterAttributeWillpower:
						willpowerEnhancer = enhancer;
						break;
				}
			}
			
			if (intelligenceEnhancer)
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Intelligence %d (%d + %d)", nil),
											 characterSheet.attributes.intelligence + intelligenceEnhancer.augmentatorValue,
											 characterSheet.attributes.intelligence,
											 intelligenceEnhancer.augmentatorValue],
				 @"value": intelligenceEnhancer.augmentatorName}];
			else
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Intelligence %d", nil),
											 characterSheet.attributes.intelligence]}];

			if (memoryEnhancer)
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Memory %d (%d + %d)", nil),
											 characterSheet.attributes.memory + memoryEnhancer.augmentatorValue,
											 characterSheet.attributes.memory,
											 memoryEnhancer.augmentatorValue],
				 @"value": memoryEnhancer.augmentatorName}];
			else
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Memory %d", nil),
											 characterSheet.attributes.memory]}];

			if (perceptionEnhancer)
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Perception %d (%d + %d)", nil),
											 characterSheet.attributes.perception + perceptionEnhancer.augmentatorValue,
											 characterSheet.attributes.perception,
											 perceptionEnhancer.augmentatorValue],
				 @"value": perceptionEnhancer.augmentatorName}];
			else
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Perception %d", nil),
											 characterSheet.attributes.perception]}];

			if (willpowerEnhancer)
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Willpower %d (%d + %d)", nil),
											 characterSheet.attributes.willpower + willpowerEnhancer.augmentatorValue,
											 characterSheet.attributes.willpower,
											 willpowerEnhancer.augmentatorValue],
				 @"value": willpowerEnhancer.augmentatorName}];
			else
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Willpower %d", nil),
											 characterSheet.attributes.willpower]}];
			
			if (charismaEnhancer)
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Charisma %d (%d + %d)", nil),
											 characterSheet.attributes.charisma + charismaEnhancer.augmentatorValue,
											 characterSheet.attributes.charisma,
											 charismaEnhancer.augmentatorValue],
				 @"value": charismaEnhancer.augmentatorName}];
			else
				[rows addObject:@{@"title": [NSString stringWithFormat:NSLocalizedString(@"Charisma %d", nil),
											 characterSheet.attributes.charisma]}];

			[sections addObject:section];

			rows = [NSMutableArray new];
			section = @{@"rows": rows, @"title": characterSheet.cloneName ? characterSheet.cloneName : NSLocalizedString(@"No clone", nil)};

			int skillpoints = 0;
			for (EVECharacterSheetSkill *skill in characterSheet.skills)
				skillpoints += skill.skillpoints;
			UIColor* color = skillpoints > characterSheet.cloneSkillPoints ? [UIColor redColor] : [UIColor greenColor];

			[rows addObject:@{@"title": NSLocalizedString(@"Total skillpoints", nil),
			 @"value": [NSNumberFormatter neocomLocalizedStringFromInteger:skillpoints]}];
			
			[rows addObject:@{@"title": NSLocalizedString(@"Clone skillpoints", nil),
			 @"value": [NSNumberFormatter neocomLocalizedStringFromInteger:characterSheet.cloneSkillPoints],
			 @"color": color}];
			[sections addObject:section];

		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.sections = sections;
			[self.tableView reloadData];
			
			NSURL* portraitURL = nil;
			NSURL* corpURL = nil;
			NSURL* allianceURL = nil;
			CGFloat scale = [[UIScreen mainScreen] scale];
			if (scale == 2.0) {
				portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.character.characterID size:EVEImageSize512 error:nil];
				corpURL = [EVEImage corporationLogoURLWithCorporationID:account.character.corporationID size:EVEImageSize128 error:nil];
				if (account.characterSheet.allianceID)
					allianceURL = [EVEImage allianceLogoURLWithAllianceID:account.characterSheet.allianceID size:EVEImageSize128 error:nil];
			}
			else {
				portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.character.characterID size:EVEImageSize256 error:nil];
				corpURL = [EVEImage corporationLogoURLWithCorporationID:account.character.corporationID size:EVEImageSize64 error:nil];
				if (account.characterSheet.allianceID)
					allianceURL = [EVEImage allianceLogoURLWithAllianceID:account.characterSheet.allianceID size:EVEImageSize64 error:nil];
			}
			[self.portraitImageView setImageWithContentsOfURL:portraitURL scale:scale completion:nil failureBlock:nil];
			[self.corpImageView setImageWithContentsOfURL:corpURL scale:scale completion:nil failureBlock:nil];
			if (allianceURL)
				[self.allianceImageView setImageWithContentsOfURL:allianceURL scale:scale completion:nil failureBlock:nil];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
