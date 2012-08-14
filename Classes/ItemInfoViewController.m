//
//  ItemInfoViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ItemInfoViewController.h"
#import "AttributeCellView.h"
#import "ItemInfoSkillCellView.h"
#import "ItemsDBViewController.h"
#import "ItemViewController.h"
#import "NibTableViewCell.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "SkillTree.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "NSString+HTML.h"
#import "TrainingQueue.h"
#import "NSString+TimeLeft.h"
#import "EVEDBCrtCertificate+TrainingQueue.h"
#import "CertificateCellView.h"
#import "EVEDBCrtCertificate+State.h"
#import "CertificateViewController.h"


@interface ItemInfoViewController(Private)
- (void) loadAttributes;
- (void) loadNPCAttributes;
- (void) loadBlueprintAttributes;
@end


@implementation ItemInfoViewController
@synthesize attributesTable;
@synthesize titleLabel;
@synthesize volumeLabel;
@synthesize massLabel;
@synthesize capacityLabel;
@synthesize radiusLabel;
@synthesize descriptionLabel;
@synthesize imageView;
@synthesize techLevelImageView;
@synthesize typeInfoView;
@synthesize containerViewController;
@synthesize type;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.titleLabel.text = type.typeName;
	self.title = @"Info";
	volumeLabel.text = [NSString stringWithFormat:@"%@ m3", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:type.volume] numberStyle:NSNumberFormatterDecimalStyle]];
	massLabel.text = [NSString stringWithFormat:@"%@ kg", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:type.mass] numberStyle:NSNumberFormatterDecimalStyle]];
	capacityLabel.text = [NSString stringWithFormat:@"%@ m3", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:type.capacity] numberStyle:NSNumberFormatterDecimalStyle]];
	radiusLabel.text = [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:type.radius] numberStyle:NSNumberFormatterDecimalStyle]];
	NSString* s = [[type.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
	NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
	[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];
	descriptionLabel.text = description;
	imageView.image = [UIImage imageNamed:[type typeLargeImageName]];
	CGRect r = [descriptionLabel textRectForBounds:CGRectMake(0, 0, descriptionLabel.frame.size.width, 1024) limitedToNumberOfLines:0];
	descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, r.size.height);
	typeInfoView.frame = CGRectMake(typeInfoView.frame.origin.x, typeInfoView.frame.origin.y, typeInfoView.frame.size.width, descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 5);
	attributesTable.tableHeaderView.frame = typeInfoView.frame;
	
	EVEDBDgmTypeAttribute *attribute = [type.attributesDictionary valueForKey:@"422"];
	int techLevel = attribute.value;
	if (techLevel == 1)
		techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_140.png"];
	else if (techLevel == 2)
		techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_141.png"];
	else if (techLevel == 3)
		techLevelImageView.image = [UIImage imageNamed:@"Icons/icon38_142.png"];
	else
		techLevelImageView.image = nil;
	
	trainingTime = 0;
	sections = [[NSMutableArray alloc] init];
	if (type.group.categoryID == 11)
		[self loadNPCAttributes];
	else if (type.group.categoryID == 9)
		[self loadBlueprintAttributes];
	else
		[self loadAttributes];
	
//	attributesTable.frame = CGRectMake(attributesTable.frame.origin.x, typeInfoView.frame.size.height, attributesTable.frame.size.width, self.view.frame.size.height);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.attributesTable = nil;
	self.titleLabel = nil;
	self.volumeLabel = nil;
	self.massLabel = nil;
	self.capacityLabel = nil;
	self.radiusLabel = nil;
	self.descriptionLabel = nil;
	self.imageView = nil;
	self.techLevelImageView = nil;
	self.typeInfoView = nil;
	[sections release];
	sections = nil;
	[modifiedIndexPath release];
	modifiedIndexPath = nil;
}


- (void)dealloc {
	[attributesTable release];
	[titleLabel release];
	[volumeLabel release];
	[massLabel release];
	[capacityLabel release];
	[radiusLabel release];
	[descriptionLabel release];
	[imageView release];
	[techLevelImageView release];
	[typeInfoView release];
	[type release];
	[sections release];
	[modifiedIndexPath release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[sections objectAtIndex:section] valueForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] valueForKey:@"name"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	NSInteger cellType = [[row valueForKey:@"cellType"] integerValue];
	if (cellType == 0 || cellType == 2 || cellType == 4 || cellType == 5) {
		static NSString *cellIdentifier = @"AttributeCellView";
		
		AttributeCellView *cell = (AttributeCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [AttributeCellView cellWithNibName:@"AttributeCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.attributeNameLabel.text = [row valueForKey:@"title"];
		cell.attributeValueLabel.text = [row valueForKey:@"value"];
		NSString *icon = [row valueForKey:@"icon"];
		if (icon)
			cell.iconView.image = [UIImage imageNamed:icon];
		else
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon105_32.png"];
		
		cell.accessoryType = (cellType == 2 || cellType == 5) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		
		return cell;
	}
	else if (cellType == 3) {
		NSString* value = [row valueForKeyPath:@"value"];
		NSString *cellIdentifier = value ? @"CertificateCellViewDetailed" : @"CertificateCellView";
		
		CertificateCellView *cell = (CertificateCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [CertificateCellView cellWithNibName:@"CertificateCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:[row valueForKey:@"icon"]];
		cell.titleLabel.text = [row valueForKey:@"title"];
		if (value)
			cell.detailLabel.text = value;
		cell.stateView.image = [UIImage imageNamed:[row valueForKey:@"stateIcon"]];
		
		return cell;
	}
	else {
		static NSString *cellIdentifier = @"ItemInfoSkillCellView";
		
		ItemInfoSkillCellView *cell = (ItemInfoSkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemInfoSkillCellView cellWithNibName:@"ItemInfoSkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.skillLabel.text = [row valueForKey:@"value"];
		NSString *icon = [row valueForKey:@"icon"];

		if (icon)
			cell.iconView.image = [UIImage imageNamed:icon];
		else
			cell.iconView.image = nil;

		NSInteger hierarchyLevel = [[row valueForKey:@"type"] hierarchyLevel];
		float rightBorder = cell.hierarchyView.frame.origin.x + cell.hierarchyView.frame.size.width;
		cell.hierarchyView.frame = CGRectMake(hierarchyLevel * 16, cell.hierarchyView.frame.origin.y, rightBorder - (hierarchyLevel * 16), cell.hierarchyView.frame.size.height);
		return cell;
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:14];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row = [[[sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	
	NSInteger cellType = [[row valueForKey:@"cellType"] integerValue];
	if (cellType == 1 || cellType == 5) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																			  bundle:nil];
		controller.type = [row valueForKey:@"type"];
		[controller setActivePage:ItemViewControllerActivePageInfo];
		[self.containerViewController.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (cellType == 2) {
		ItemsDBViewController *controller = [[ItemsDBViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemsDBViewControllerModal-iPad" : @"ItemsDBViewController")
																					bundle:nil];
		controller.modalMode = YES;
		controller.group = [row valueForKey:@"group"];
		controller.category = controller.group.category;
		[self.containerViewController.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (cellType == 3) {
		CertificateViewController* controller = [[CertificateViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"CertificateViewController-iPad" : @"CertificateViewController")
																							bundle:nil];
		controller.certificate = [row valueForKey:@"certificate"];
		[self.containerViewController.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if (cellType == 4) {
		[modifiedIndexPath release];
		modifiedIndexPath = [indexPath retain];

		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		TrainingQueue* trainingQueue = [row valueForKey:@"trainingQueue"];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Add to skill plan?"
															message:[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
														   delegate:self
												  cancelButtonTitle:@"No"
												  otherButtonTitles:@"Yes", nil];
		[alertView show];
		[alertView autorelease];
	}
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSDictionary *row = [[[sections objectAtIndex:modifiedIndexPath.section] valueForKey:@"rows"] objectAtIndex:modifiedIndexPath.row];
		TrainingQueue* trainingQueue = [row valueForKey:@"trainingQueue"];
		SkillPlan* skillPlan = [[EVEAccount currentAccount] skillPlan];
		for (EVEDBInvTypeRequiredSkill* skill in trainingQueue.skills)
			[skillPlan addSkill:skill];
		[skillPlan save];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Skill plan updated"
															message:[NSString stringWithFormat:@"Total training time: %@", [NSString stringWithTimeLeft:skillPlan.trainingTime]]
														   delegate:nil
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView autorelease];
	}
}

@end


@implementation ItemInfoViewController(Private)

- (void) loadAttributes {
	[[EUOperationQueue sharedQueue] addOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		trainingTime = [[TrainingQueue trainingQueueWithType:type] trainingTime];
		NSDictionary *skillRequirementsMap = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"skillRequirementsMap" ofType:@"plist"]]];
		EVEAccount *account = [EVEAccount currentAccount];
		[account updateSkillpoints];
		
		TrainingQueue* requiredSkillsQueue = nil;
		TrainingQueue* certificateRecommendationsQueue = nil;
		if (account && account.skillPlan && (type.requiredSkills.count > 0 || type.certificateRecommendations.count > 0 || type.group.categoryID == 16)) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			[section setValue:@"Skill Plan" forKey:@"name"];
			NSMutableArray* rows = [NSMutableArray array];
			[section setValue:rows forKey:@"rows"];

			requiredSkillsQueue = [[[TrainingQueue alloc] initWithType:type] autorelease];
			certificateRecommendationsQueue = [[[TrainingQueue alloc] init] autorelease];
			
			for (EVEDBCrtRecommendation* recommendation in type.certificateRecommendations) {
				for (EVEDBInvTypeRequiredSkill* skill in recommendation.certificate.trainingQueue.skills)
					[certificateRecommendationsQueue addSkill:skill];
			}
			
			if (type.group.categoryID == 16) {
				EVECharacterSheetSkill* characterSkill = [account.characterSheet.skillsMap valueForKey:[NSString stringWithFormat:@"%d", type.typeID]];
				NSString* romanNumbers[] = {@"0", @"I", @"II", @"III", @"IV", @"V"};
				for (NSInteger level = characterSkill.level + 1; level <= 5; level++) {
					TrainingQueue* trainingQueue = [[[TrainingQueue alloc] init] autorelease];
					[trainingQueue.skills addObjectsFromArray:requiredSkillsQueue.skills];
					EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithInvType:type];
					skill.requiredLevel = level;
					skill.currentLevel = characterSkill.level;
					[trainingQueue addSkill:skill];
					
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:4], @"cellType", 
												[NSString stringWithFormat:@"Train to level %@", romanNumbers[level]], @"title",
												[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:trainingQueue.trainingTime]], @"value",
												trainingQueue, @"trainingQueue",
												@"Icons/icon50_13.png", @"icon",
												nil];
					[rows addObject:row];
				}
			}
			else {
				if (requiredSkillsQueue.skills.count) {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:4], @"cellType", 
												@"Add required skills to training plan", @"title",
												[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]], @"value",
												requiredSkillsQueue, @"trainingQueue",
												@"Icons/icon50_13.png", @"icon",
												nil];
					[rows addObject:row];
				}
				if (certificateRecommendationsQueue.skills.count) {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:4], @"cellType", 
												@"Add recommended certificates to training plan", @"title",
												[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:certificateRecommendationsQueue.trainingTime]], @"value",
												certificateRecommendationsQueue, @"trainingQueue",
												@"Icons/icon79_06.png", @"icon",
												nil];
					[rows addObject:row];
				}
			}
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		if (type.blueprint) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			[section setValue:@"Manufacturing" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithInteger:5], @"cellType",
							 @"Blueprint", @"title",
							 [self.type.blueprint typeName], @"value",
							 [self.type.blueprint typeSmallImageName], @"icon",
							 self.type.blueprint, @"type",
							 nil]];
			[sections addObject:section];
		}
		
		for (EVEDBInvTypeAttributeCategory *category in type.attributeCategories) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			
			if (category.categoryID == 8 && trainingTime > 0) {
				NSString *name = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingTime]];
				[section setValue:name forKey:@"name"];
			}
			else
				[section setValue:category.categoryID == 9 ? @"Other" : category.categoryName
						   forKey:@"name"];
			
			[section setValue:rows forKey:@"rows"];
			
			for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
				if (attribute.attribute.unitID == 119) {
					int attributeID = attribute.value;
					EVEDBDgmAttributeType *dgmAttribute = [EVEDBDgmAttributeType dgmAttributeTypeWithAttributeTypeID:attributeID error:nil];
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:0], @"cellType", 
												attribute.attribute.displayName, @"title",
												dgmAttribute.displayName, @"value",
												nil];
					if (dgmAttribute.icon.iconImageName)
						[row setValue:dgmAttribute.icon.iconImageName forKey:@"icon"];
					[rows addObject:row];
				}
				else if (attribute.attribute.unitID == 116) {
					int typeID = attribute.value;
					EVEDBInvType *skill = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
					if (skill) {
						for (NSDictionary *requirementMap in skillRequirementsMap) {
							if ([[requirementMap valueForKey:SkillTreeRequirementIDKey] integerValue] == attribute.attributeID) {
								EVEDBDgmTypeAttribute *level = [type.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeSkillLevelIDKey]];
								SkillTree *skillTree = [SkillTree skillTreeWithRootSkill:skill skillLevel:level.value];
								for (SkillTreeItem *skill in skillTree.skills) {
									NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																[NSNumber numberWithInteger:1], @"cellType", 
																[NSString stringWithFormat:@"%@ %@", skill.typeName, [skill romanSkillLevel]], @"value",
																skill, @"type",
																nil];
									switch (skill.skillAvailability) {
										case SkillTreeItemAvailabilityLearned:
											[row setValue:@"Icons/icon38_193.png" forKey:@"icon"];
											break;
										case SkillTreeItemAvailabilityNotLearned:
											[row setValue:@"Icons/icon38_194.png" forKey:@"icon"];
											break;
										case SkillTreeItemAvailabilityLowLevel:
											[row setValue:@"Icons/icon38_195.png" forKey:@"icon"];
											break;
										default:
											break;
									}
									[rows addObject:row];
								}
								break;
							}
						}
					}
				}
				else if (attribute.attribute.unitID == 115) {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:2], @"cellType", 
												attribute.attribute.displayName, @"title",
												nil];
					int groupID = attribute.value;
					EVEDBInvGroup *group = [EVEDBInvGroup invGroupWithGroupID:groupID error:nil];
					[row setValue:group.groupName forKey:@"value"];
					[row setValue:group forKey:@"group"];
					if (attribute.attribute.icon.iconImageName)
						[row setValue:attribute.attribute.icon.iconImageName forKey:@"icon"];
					else if (group.icon.iconImageName)
						[row setValue:group.icon.iconImageName forKey:@"icon"];
					[rows addObject:row];
				}
				else if (attribute.attribute.unitID == 117) {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:0], @"cellType", 
												attribute.attribute.displayName, @"title",
												nil];
					int size = attribute.value;
					if (size == 1)
						[row setValue:@"Small" forKey:@"value"];
					else if (size == 2)
						[row setValue:@"Medium" forKey:@"value"];
					else
						[row setValue:@"Large" forKey:@"value"];
					if (attribute.attribute.icon.iconImageName)
						[row setValue:attribute.attribute.icon.iconImageName forKey:@"icon"];
					[rows addObject:row];
				}
				else {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:0], @"cellType", 
												attribute.attribute.displayName, @"title",
												nil];
					if (attribute.attributeID == 280) {
						NSInteger level = 0;
						EVECharacterSheetSkill *skill = [account.characterSheet.skillsMap valueForKey:[NSString stringWithFormat:@"%d", type.typeID]];
						if (skill)
							level = skill.level;
						[row setValue:[NSString stringWithFormat:@"%d", level] forKey:@"value"];
					}
					else {
						NSNumber *value;
						NSString *unit;
						
						if (attribute.attributeID == 1281) {
							float v = [(EVEDBDgmTypeAttribute*) [type.attributesDictionary valueForKey:@"600"] value];
							if (v == 0.0)
								v = 1.0;
							value = [NSNumber numberWithFloat:3 * v];
							unit = @"AU/sec";
						}
						else if (attribute.attribute.unit.unitID == 108 || attribute.attribute.unit.unitID == 111) {
							float v = attribute.value;
							v = (1 - v) * 100;
							value = [NSNumber numberWithFloat:v];
							unit = attribute.attribute.unit.displayName;
						}
						else if (attribute.attribute.unit.unitID == 109) {
							float v = attribute.value;
							v = (v - 1) * 100;
							value = [NSNumber numberWithFloat:v];
							unit = attribute.attribute.unit.displayName;
						}
						else if (attribute.attribute.unit.unitID == 127) {
							float v = attribute.value;
							v *= 100;
							value = [NSNumber numberWithFloat:v];
							unit = attribute.attribute.unit.displayName;
						}
						else if (attribute.attribute.unit.unitID == 101) {
							float v = attribute.value;
							v /= 1000.0;
							value = [NSNumber numberWithFloat:v];
							unit = attribute.attribute.unit.displayName;
						}
						else {
							value = [NSNumber numberWithFloat:attribute.value];
							unit = attribute.attribute.unit.displayName;
						}
						
						[row setValue:[NSString stringWithFormat:@"%@ %@",
									   [NSNumberFormatter localizedStringFromNumber:value numberStyle:NSNumberFormatterDecimalStyle],
									   unit ? unit : @""]
							   forKey:@"value"];
					}
					if (attribute.attribute.icon.iconImageName)
						[row setValue:attribute.attribute.icon.iconImageName forKey:@"icon"];
					[rows addObject:row];
				}
			}
			if (rows.count > 0)
				[sections addObject:section];
		}
		if (type.group.category.categoryID == 16) { //Skill
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account || account.characterSheet == nil)
				account = [EVEAccount dummyAccount];
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			[section setValue:@"Training time" forKey:@"name"];
			[sections addObject:section];
			float startSP = 0;
			float endSP;
			for (int i = 1; i <= 5; i++) {
				endSP = [type skillpointsAtLevel:i];
				NSTimeInterval needsTime = (endSP - startSP) / [account.characterAttributes skillpointsPerSecondForSkill:type];
				NSString *text = [NSString stringWithFormat:@"SP: %@ (%@)",
								  [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:endSP] numberStyle:NSNumberFormatterDecimalStyle],
								  [NSString stringWithTimeLeft:needsTime]];

				NSString *rank = (i == 1 ? @"Level I" : (i == 2 ? @"Level II" : (i == 3 ? @"Level III" : (i == 4 ? @"Level IV" : @"Level V"))));
				
				NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:0], @"cellType", 
									 rank, @"title",
									 text, @"value",
									 @"Icons/icon50_13.png", @"icon", nil];
				[rows addObject:row];
				startSP = endSP;
			}
			[section setValue:rows forKey:@"rows"];
		}
		
		if (type.certificateRecommendations.count > 0) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			TrainingQueue* trainingQueue = [[TrainingQueue alloc] init];
			[sections addObject:section];

			for (EVEDBCrtRecommendation* recommendation in type.certificateRecommendations) {
				NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInteger:3], @"cellType",
											recommendation.certificate, @"certificate",
											[NSString stringWithFormat:@"%@ - %@", recommendation.certificate.certificateClass.className, recommendation.certificate.gradeText], @"title",
											recommendation.certificate.iconImageName, @"icon", nil];
				if (recommendation.certificate.trainingQueue.trainingTime > 0)
					[row setValue:[NSString stringWithFormat:@"Training time: %@",
								   [NSString stringWithTimeLeft:recommendation.certificate.trainingQueue.trainingTime]]
						   forKey:@"value"];
				[row setValue:recommendation.certificate.stateIconImageName forKey:@"stateIcon"];
				for (EVEDBInvTypeRequiredSkill* skill in recommendation.certificate.trainingQueue.skills)
					[trainingQueue addSkill:skill];
				[rows addObject:row];
			}
			
			if (trainingQueue.trainingTime > 0)
				[section setValue:[NSString stringWithFormat:@"Recommended certificates (%@)", [NSString stringWithTimeLeft:trainingQueue.trainingTime]] forKey:@"name"];
			else
				[section setValue:@"Recommended certificates" forKey:@"name"];
			[trainingQueue release];
			[section setValue:rows forKey:@"rows"];
		}
		
		[self.attributesTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		[pool release];
	}];
}

- (void) loadNPCAttributes {
	[[EUOperationQueue sharedQueue] addOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		EVEDBDgmTypeAttribute* emDamageAttribute = [type.attributesDictionary valueForKey:@"114"];
		EVEDBDgmTypeAttribute* explosiveDamageAttribute = [type.attributesDictionary valueForKey:@"116"];
		EVEDBDgmTypeAttribute* kineticDamageAttribute = [type.attributesDictionary valueForKey:@"117"];
		EVEDBDgmTypeAttribute* thermalDamageAttribute = [type.attributesDictionary valueForKey:@"118"];
		EVEDBDgmTypeAttribute* damageMultiplierAttribute = [type.attributesDictionary valueForKey:@"64"];
		EVEDBDgmTypeAttribute* missileDamageMultiplierAttribute = [type.attributesDictionary valueForKey:@"212"];
		EVEDBDgmTypeAttribute* missileTypeIDAttribute = [type.attributesDictionary valueForKey:@"507"];
		EVEDBDgmTypeAttribute* missileVelocityMultiplierAttribute = [type.attributesDictionary valueForKey:@"645"];
		EVEDBDgmTypeAttribute* missileFlightTimeMultiplierAttribute = [type.attributesDictionary valueForKey:@"646"];
		
		EVEDBDgmTypeAttribute* armorEmDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"267"];
		EVEDBDgmTypeAttribute* armorExplosiveDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"268"];
		EVEDBDgmTypeAttribute* armorKineticDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"269"];
		EVEDBDgmTypeAttribute* armorThermalDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"270"];

		EVEDBDgmTypeAttribute* shieldEmDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"271"];
		EVEDBDgmTypeAttribute* shieldExplosiveDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"272"];
		EVEDBDgmTypeAttribute* shieldKineticDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"273"];
		EVEDBDgmTypeAttribute* shieldThermalDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"274"];

		EVEDBDgmTypeAttribute* structureEmDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"113"];
		EVEDBDgmTypeAttribute* structureExplosiveDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"111"];
		EVEDBDgmTypeAttribute* structureKineticDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"109"];
		EVEDBDgmTypeAttribute* structureThermalDamageResonanceAttribute = [type.attributesDictionary valueForKey:@"110"];

		EVEDBDgmTypeAttribute* armorHPAttribute = [type.attributesDictionary valueForKey:@"265"];
		EVEDBDgmTypeAttribute* hpAttribute = [type.attributesDictionary valueForKey:@"9"];
		EVEDBDgmTypeAttribute* shieldCapacityAttribute = [type.attributesDictionary valueForKey:@"263"];
		EVEDBDgmTypeAttribute* shieldRechargeRate = [type.attributesDictionary valueForKey:@"479"];

		EVEDBDgmTypeAttribute* optimalAttribute = [type.attributesDictionary valueForKey:@"54"];
		EVEDBDgmTypeAttribute* falloffAttribute = [type.attributesDictionary valueForKey:@"158"];
		EVEDBDgmTypeAttribute* trackingSpeedAttribute = [type.attributesDictionary valueForKey:@"160"];

		EVEDBDgmTypeAttribute* turretFireSpeedAttribute = [type.attributesDictionary valueForKey:@"51"];
		EVEDBDgmTypeAttribute* missileLaunchDurationAttribute = [type.attributesDictionary valueForKey:@"506"];
		

		NSMutableDictionary *section;
		NSMutableArray *rows;

		//NPC Info
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"NPC Info" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* bountyAttribute = [type.attributesDictionary valueForKey:@"481"];
			if (bountyAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 bountyAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) bountyAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 bountyAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* securityStatusBonusAttribute = [type.attributesDictionary valueForKey:@"252"];
			if (securityStatusBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Security Increase", @"title",
								 [NSString stringWithFormat:@"%f", securityStatusBonusAttribute.value], @"value",
								 securityStatusBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			
			EVEDBDgmTypeAttribute* factionLossAttribute = [type.attributesDictionary valueForKey:@"562"];
			if (factionLossAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Faction Stading Loss", @"title",
								 [NSString stringWithFormat:@"%f", factionLossAttribute.value], @"value",
								 factionLossAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}

		
		//Turrets damage

		float emDamageTurret = 0;
		float explosiveDamageTurret = 0;
		float kineticDamageTurret = 0;
		float thermalDamageTurret = 0;
		float intervalTurret = 0;
		float totalDamageTurret = 0;

		if ([type.effectsDictionary valueForKey:@"10"] || [type.effectsDictionary valueForKey:@"1086"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Turrets Damage" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			float damageMultiplier = [damageMultiplierAttribute value];
			if (damageMultiplier == 0)
				damageMultiplier = 1;

			emDamageTurret = [emDamageAttribute value] * damageMultiplier;
			explosiveDamageTurret = [explosiveDamageAttribute value] * damageMultiplier;
			kineticDamageTurret = [kineticDamageAttribute value] * damageMultiplier;
			thermalDamageTurret = [thermalDamageAttribute value] * damageMultiplier;
			intervalTurret = [turretFireSpeedAttribute value] / 1000.0;
			totalDamageTurret = emDamageTurret + explosiveDamageTurret + kineticDamageTurret + thermalDamageTurret;
			float optimal = [optimalAttribute value];
			float fallof = [falloffAttribute value];
			float trackingSpeed = [trackingSpeedAttribute value];

			float tmpInterval = intervalTurret > 0 ? intervalTurret : 1;
			
			NSString* titles[] = {@"Em damage", @"Explosive damage", @"Kinetic damage", @"Thermal damage", @"Total damage", @"Rate of fire", @"Optimal range", @"Falloff", @"Tracking speed"};
			NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"turrets.png", @"Icons/icon22_21.png", @"Icons/icon22_15.png", @"Icons/icon22_23.png", @"Icons/icon22_22.png"};
			NSString* values[] = {
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageTurret, emDamageTurret / tmpInterval, totalDamageTurret > 0 ? emDamageTurret / totalDamageTurret * 100 : 0.0],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageTurret, explosiveDamageTurret / tmpInterval, totalDamageTurret > 0 ? explosiveDamageTurret / totalDamageTurret * 100 : 0.0],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageTurret, kineticDamageTurret / tmpInterval, totalDamageTurret > 0 ? kineticDamageTurret / totalDamageTurret * 100 : 0.0],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageTurret, thermalDamageTurret / tmpInterval, totalDamageTurret > 0 ? thermalDamageTurret / totalDamageTurret * 100 : 0.0],
				[NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageTurret, totalDamageTurret / tmpInterval],
				[NSString stringWithFormat:@"%.2f s", intervalTurret],
				[NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:optimal] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:fallof] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%f rad/sec", trackingSpeed]
			};
			
			for (int i = 0; i < 9; i++) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 titles[i], @"title",
								 values[i], @"value",
								 icons[i], @"icon",
								 nil]];
			}
			[sections addObject:section];
		}
		
		//Missiles damage
		float emDamageMissile = 0;
		float explosiveDamageMissile = 0;
		float kineticDamageMissile = 0;
		float thermalDamageMissile = 0;
		float intervalMissile = 0;
		float totalDamageMissile = 0;

		if ([type.effectsDictionary valueForKey:@"569"]) {
			EVEDBInvType* missile = [EVEDBInvType invTypeWithTypeID:(NSInteger)[missileTypeIDAttribute value] error:nil];
			if (missile) {
				section = [NSMutableDictionary dictionary];
				rows = [NSMutableArray array];
				[section setValue:@"Missiles Damage" forKey:@"name"];
				[section setValue:rows forKey:@"rows"];
				
				EVEDBDgmTypeAttribute* emDamageAttribute = [missile.attributesDictionary valueForKey:@"114"];
				EVEDBDgmTypeAttribute* explosiveDamageAttribute = [missile.attributesDictionary valueForKey:@"116"];
				EVEDBDgmTypeAttribute* kineticDamageAttribute = [missile.attributesDictionary valueForKey:@"117"];
				EVEDBDgmTypeAttribute* thermalDamageAttribute = [missile.attributesDictionary valueForKey:@"118"];
				EVEDBDgmTypeAttribute* maxVelocityAttribute = [missile.attributesDictionary valueForKey:@"37"];
				EVEDBDgmTypeAttribute* explosionDelayAttribute = [missile.attributesDictionary valueForKey:@"281"];
				EVEDBDgmTypeAttribute* agilityAttribute = [missile.attributesDictionary valueForKey:@"70"];
				
				float missileDamageMultiplier = [missileDamageMultiplierAttribute value];
				if (missileDamageMultiplier == 0)
					missileDamageMultiplier = 1;
				
				emDamageMissile = [emDamageAttribute value] * missileDamageMultiplier;
				explosiveDamageMissile = [explosiveDamageAttribute value] * missileDamageMultiplier;
				kineticDamageMissile = [kineticDamageAttribute value] * missileDamageMultiplier;
				thermalDamageMissile = [thermalDamageAttribute value] * missileDamageMultiplier;
				intervalMissile = [missileLaunchDurationAttribute value] / 1000.0;
				totalDamageMissile = emDamageMissile + explosiveDamageMissile + kineticDamageMissile + thermalDamageMissile;
				
				float missileVelocityMultiplier = missileVelocityMultiplierAttribute.value;
				if (missileVelocityMultiplier == 0)
					missileVelocityMultiplier = 1;
				float missileFlightTimeMultiplier = missileFlightTimeMultiplierAttribute.value;
				if (missileFlightTimeMultiplier == 0)
					missileFlightTimeMultiplier = 1;
				
				float maxVelocity = maxVelocityAttribute.value * missileVelocityMultiplier;
				float flightTime = explosionDelayAttribute.value * missileFlightTimeMultiplier / 1000.0;
				float mass = missile.mass;
				float agility = agilityAttribute.value;
				
				float accelTime = MIN(flightTime, mass * agility / 1000000.0);
				float duringAcceleration = maxVelocity / 2 * accelTime;
				float fullSpeed = maxVelocity * (flightTime - accelTime);
				float optimal =  duringAcceleration + fullSpeed;
				
				float tmpInterval = intervalMissile > 0 ? intervalMissile : 1;

				NSString* titles[] = {@"Em damage", @"Explosive damage", @"Kinetic damage", @"Thermal damage", @"Total damage", @"Rate of fire", @"Optimal range"};
				NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"launchers.png", @"Icons/icon22_21.png", @"Icons/icon22_15.png"};
				NSString* values[] = {
					[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageMissile, emDamageMissile / tmpInterval, totalDamageMissile > 0 ? emDamageMissile / totalDamageMissile * 100 : 0.0],
					[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageMissile, explosiveDamageMissile / tmpInterval, totalDamageMissile > 0 ? explosiveDamageMissile / totalDamageMissile * 100 : 0.0],
					[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageMissile, kineticDamageMissile / tmpInterval, totalDamageMissile > 0 ? kineticDamageMissile / totalDamageMissile * 100 : 0.0],
					[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageMissile, thermalDamageMissile / tmpInterval, totalDamageMissile > 0 ? thermalDamageMissile / totalDamageMissile * 100 : 0.0],
					[NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageMissile, totalDamageMissile / tmpInterval],
					[NSString stringWithFormat:@"%.2f s", intervalMissile],
					[NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:optimal] numberStyle:NSNumberFormatterDecimalStyle]]
				};
				
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:5], @"cellType", 
								 @"Missile Type", @"title",
								 missile.typeName, @"value",
								 [missile typeSmallImageName], @"icon",
								 missile, @"type",
								 nil]];
				
				for (int i = 0; i < 7; i++) {
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:0], @"cellType", 
									 titles[i], @"title",
									 values[i], @"value",
									 icons[i], @"icon",
									 nil]];
				}
				[sections addObject:section];
			}
		}
		
		//Total damage
		if (totalDamageTurret > 0 && totalDamageMissile > 0) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Total Damage" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			float emDPSTurret = emDamageTurret / intervalTurret;
			float explosiveDPSTurret = explosiveDamageTurret / intervalTurret;
			float kineticDPSTurret = kineticDamageTurret / intervalTurret;
			float thermalDPSTurret = thermalDamageTurret / intervalTurret;
			float totalDPSTurret = emDPSTurret + explosiveDPSTurret + kineticDPSTurret + thermalDPSTurret;
			
			if (intervalMissile == 0)
				intervalMissile = 1;

			float emDPSMissile = emDamageMissile / intervalMissile;
			float explosiveDPSMissile = explosiveDamageMissile / intervalMissile;
			float kineticDPSMissile = kineticDamageMissile / intervalMissile;
			float thermalDPSMissile = thermalDamageMissile / intervalMissile;
			float totalDPSMissile = emDPSMissile + explosiveDPSMissile + kineticDPSMissile + thermalDPSMissile;
			
			float emDPS = emDPSTurret + emDPSMissile;
			float explosiveDPS = explosiveDPSTurret + explosiveDPSMissile;
			float kineticDPS = kineticDPSTurret + kineticDPSMissile;
			float thermalDPS = thermalDPSTurret + thermalDPSMissile;
			float totalDPS = totalDPSTurret + totalDPSMissile;
			
			
			NSString* titles[] = {@"Em damage", @"Explosive damage", @"Kinetic damage", @"Thermal damage", @"Total damage"};
			NSString* icons[] = {@"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"dps.png"};
			NSString* values[] = {
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", emDamageTurret + emDamageMissile, emDPS, emDPS / totalDPS * 100],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", explosiveDamageTurret + explosiveDamageMissile, explosiveDPS, explosiveDPS / totalDPS * 100],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", kineticDamageTurret + kineticDamageMissile, kineticDPS, kineticDPS / totalDPS * 100],
				[NSString stringWithFormat:@"%.2f (%.2f/s, %.0f%%)", thermalDamageTurret + thermalDamageMissile, thermalDPS, thermalDPS / totalDPS * 100],
				[NSString stringWithFormat:@"%.2f (%.2f/s)", totalDamageTurret + totalDamageMissile, totalDPS]
			};
			
			for (int i = 0; i < 5; i++) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 titles[i], @"title",
								 values[i], @"value",
								 icons[i], @"icon",
								 nil]];
			}
			[sections addObject:section];
		}
		
		//Shield
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Shield" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];

			float passiveRechargeRate = shieldRechargeRate.value > 0 ? 10.0 / (shieldRechargeRate.value / 1000.0) * 0.5 * (1 - 0.5) * shieldCapacityAttribute.value : 0;
			float em = shieldEmDamageResonanceAttribute ? shieldEmDamageResonanceAttribute.value : 1;
			float explosive = shieldExplosiveDamageResonanceAttribute ? shieldExplosiveDamageResonanceAttribute.value : 1;
			float kinetic = shieldKineticDamageResonanceAttribute ? shieldKineticDamageResonanceAttribute.value : 1;
			float thermal = shieldThermalDamageResonanceAttribute ? shieldThermalDamageResonanceAttribute.value : 1;


			NSString* titles[] = {
				@"Shield Capacity",
				@"Shield Em Damage Resistance",
				@"Shield Explosive Damage Resistance",
				@"Shield Kinetic Damage Resistance",
				@"Shield Thermal Damage Resistance",
				@"Shield Recharge Time",
				@"Passive Recharge Rate"};
			NSString* icons[] = {@"shield.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png", @"Icons/icon22_16.png", @"shieldRecharge.png"};
			NSString* values[] = {
				[NSString stringWithFormat:@"%@ HP", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) shieldCapacityAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100],
				[NSString stringWithFormat:@"%@ s", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) shieldRechargeRate.value / 1000.0] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%.2f HP/s", passiveRechargeRate],
			};
			
			for (int i = 0; i < 7; i++) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 titles[i], @"title",
								 values[i], @"value",
								 icons[i], @"icon",
								 nil]];
			}
			
			if ([type.effectsDictionary valueForKey:@"2192"] || [type.effectsDictionary valueForKey:@"2193"] || [type.effectsDictionary valueForKey:@"2194"] || [type.effectsDictionary valueForKey:@"876"]) {
				EVEDBDgmTypeAttribute* shieldBoostAmountAttribute = [type.attributesDictionary valueForKey:@"637"];
				EVEDBDgmTypeAttribute* shieldBoostDurationAttribute = [type.attributesDictionary valueForKey:@"636"];
				EVEDBDgmTypeAttribute* shieldBoostDelayChanceAttribute = [type.attributesDictionary valueForKey:@"639"];
				
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1006"];
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1007"];
				if (!shieldBoostDelayChanceAttribute)
					shieldBoostDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1008"];
				
				float shieldBoostAmount = shieldBoostAmountAttribute.value;
				float shieldBoostDuration = shieldBoostDurationAttribute.value;
				float shieldBoostDelayChance = shieldBoostDelayChanceAttribute.value;
				float repairRate = shieldBoostDuration > 0 ? shieldBoostAmount * shieldBoostDelayChance / (shieldBoostDuration / 1000.0) : 0;
				
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Repair Rate", @"title",
								 [NSString stringWithFormat:@"%.2f HP/s", repairRate + passiveRechargeRate], @"value",
								 @"shieldBooster.png", @"icon",
								 nil]];

			}
			[sections addObject:section];
		}
		
		//Armor
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Armor" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			float em = armorEmDamageResonanceAttribute ? armorEmDamageResonanceAttribute.value : 1;
			float explosive = armorExplosiveDamageResonanceAttribute ? armorExplosiveDamageResonanceAttribute.value : 1;
			float kinetic = armorKineticDamageResonanceAttribute ? armorKineticDamageResonanceAttribute.value : 1;
			float thermal = armorThermalDamageResonanceAttribute ? armorThermalDamageResonanceAttribute.value : 1;
			
			
			NSString* titles[] = {
				@"Armor Hitpoints",
				@"Armor Em Damage Resistance",
				@"Armor Explosive Damage Resistance",
				@"Armor Kinetic Damage Resistance",
				@"Armor Thermal Damage Resistance"};
			NSString* icons[] = {@"armor.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png"};
			NSString* values[] = {
				[NSString stringWithFormat:@"%@ HP", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) armorHPAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100]
			};
			
			for (int i = 0; i < 5; i++) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 titles[i], @"title",
								 values[i], @"value",
								 icons[i], @"icon",
								 nil]];
			}
			
			if ([type.effectsDictionary valueForKey:@"2195"] || [type.effectsDictionary valueForKey:@"2196"] || [type.effectsDictionary valueForKey:@"2197"] || [type.effectsDictionary valueForKey:@"878"]) {
				EVEDBDgmTypeAttribute* armorRepairAmountAttribute = [type.attributesDictionary valueForKey:@"631"];
				EVEDBDgmTypeAttribute* armorRepairDurationAttribute = [type.attributesDictionary valueForKey:@"630"];
				EVEDBDgmTypeAttribute* armorRepairDelayChanceAttribute = [type.attributesDictionary valueForKey:@"638"];
				
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1009"];
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1010"];
				if (!armorRepairDelayChanceAttribute)
					armorRepairDelayChanceAttribute = [type.attributesDictionary valueForKey:@"1011"];
				
				float armorRepairAmount = armorRepairAmountAttribute.value;
				float armorRepairDuration = armorRepairDurationAttribute.value;
				float armorRepairDelayChance = armorRepairDelayChanceAttribute.value;
				if (armorRepairDelayChance == 0)
					armorRepairDelayChance = 1.0;
				float repairRate = armorRepairDuration > 0 ? armorRepairAmount * armorRepairDelayChance / (armorRepairDuration / 1000.0) : 0;
				
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Repair Rate", @"title",
								 [NSString stringWithFormat:@"%.2f HP/s", repairRate], @"value",
								 @"armorRepairer.png", @"icon",
								 nil]];
				
			}
			[sections addObject:section];
		}
		
		//Structure
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Structure" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];

			float em = structureEmDamageResonanceAttribute ? structureEmDamageResonanceAttribute.value : 1;
			float explosive = structureExplosiveDamageResonanceAttribute ? structureExplosiveDamageResonanceAttribute.value : 1;
			float kinetic = structureKineticDamageResonanceAttribute ? structureKineticDamageResonanceAttribute.value : 1;
			float thermal = structureThermalDamageResonanceAttribute ? structureThermalDamageResonanceAttribute.value : 1;
			
			
			NSString* titles[] = {
				@"Structure Hitpoints",
				@"Structure Em Damage Resistance",
				@"Structure Explosive Damage Resistance",
				@"Structure Kinetic Damage Resistance",
				@"Structure Thermal Damage Resistance"};
			NSString* icons[] = {@"armor.png", @"em.png", @"explosion.png", @"kinetic.png", @"thermal.png"};
			NSString* values[] = {
				[NSString stringWithFormat:@"%@ HP", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) hpAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]],
				[NSString stringWithFormat:@"%.0f %%", (1 - em) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - explosive) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - kinetic) * 100],
				[NSString stringWithFormat:@"%.0f %%", (1 - thermal) * 100]
			};
			
			for (int i = 0; i < 5; i++) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 titles[i], @"title",
								 values[i], @"value",
								 icons[i], @"icon",
								 nil]];
			}
			[sections addObject:section];
		}
		
		//Targeting
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Targeting" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* attackRangeAttribute = [type.attributesDictionary valueForKey:@"247"];
			if (attackRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Attack Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) attackRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 attackRangeAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* signatureRadiusAttribute = [type.attributesDictionary valueForKey:@"552"];
			if (signatureRadiusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 signatureRadiusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) signatureRadiusAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 signatureRadiusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			
			EVEDBDgmTypeAttribute* scanResolutionAttribute = [type.attributesDictionary valueForKey:@"564"];
			if (scanResolutionAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 scanResolutionAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.0f mm", scanResolutionAttribute.value], @"value",
								 scanResolutionAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* sensorStrengthAttribute = [type.attributesDictionary valueForKey:@"208"];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = [type.attributesDictionary valueForKey:@"209"];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = [type.attributesDictionary valueForKey:@"210"];
			if (sensorStrengthAttribute.value == 0)
				sensorStrengthAttribute = [type.attributesDictionary valueForKey:@"211"];
			if (sensorStrengthAttribute.value > 0) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 sensorStrengthAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.0f", sensorStrengthAttribute.value], @"value",
								 sensorStrengthAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}

		//Movement
		{
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Movement" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* maxVelocityAttribute = [type.attributesDictionary valueForKey:@"37"];
			if (maxVelocityAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 maxVelocityAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%@ m/s", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) maxVelocityAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 maxVelocityAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* orbitVelocityAttribute = [type.attributesDictionary valueForKey:@"508"];
			if (orbitVelocityAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 orbitVelocityAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%@ m/s", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) orbitVelocityAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_13.png", @"icon",
								 nil]];
			}
			
			
			EVEDBDgmTypeAttribute* entityFlyRangeAttribute = [type.attributesDictionary valueForKey:@"416"];
			if (entityFlyRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Orbit Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) entityFlyRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		//Stasis Webifying
		if ([type.effectsDictionary valueForKey:@"575"] || [type.effectsDictionary valueForKey:@"3714"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Stasis Webifying" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];

			EVEDBDgmTypeAttribute* speedFactorAttribute = [type.attributesDictionary valueForKey:@"20"];
			if (speedFactorAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 speedFactorAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.0f %%", speedFactorAttribute.value], @"value",
								 speedFactorAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedRangeAttribute = [type.attributesDictionary valueForKey:@"514"];
			if (modifyTargetSpeedRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) modifyTargetSpeedRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"targetingRange.png", @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedDurationAttribute = [type.attributesDictionary valueForKey:@"513"];
			if (modifyTargetSpeedDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", modifyTargetSpeedDurationAttribute.value / 1000.0], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* modifyTargetSpeedChanceAttribute = [type.attributesDictionary valueForKey:@"512"];
			if (modifyTargetSpeedChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Webbing Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", modifyTargetSpeedChanceAttribute.value * 100], @"value",
								 modifyTargetSpeedChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			if (rows.count > 0)
				[sections addObject:section];
		}
		
		//Warp Scramble
		if ([type.effectsDictionary valueForKey:@"39"] || [type.effectsDictionary valueForKey:@"563"] || [type.effectsDictionary valueForKey:@"3713"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Warp Scramble" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* warpScrambleStrengthAttribute = [type.attributesDictionary valueForKey:@"105"];
			if (warpScrambleStrengthAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 warpScrambleStrengthAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.0f", warpScrambleStrengthAttribute.value], @"value",
								 warpScrambleStrengthAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleRangeAttribute = [type.attributesDictionary valueForKey:@"103"];
			if (warpScrambleRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 warpScrambleRangeAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) warpScrambleRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 warpScrambleRangeAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleDurationAttribute = [type.attributesDictionary valueForKey:@"505"];
			if (warpScrambleDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 warpScrambleDurationAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.2f s", warpScrambleDurationAttribute.value / 1000], @"value",
								 warpScrambleDurationAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* warpScrambleChanceAttribute = [type.attributesDictionary valueForKey:@"504"];
			if (warpScrambleChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Scrambling Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", warpScrambleChanceAttribute.value * 100], @"value",
								 warpScrambleChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}

		//Target Painting
		if ([type.effectsDictionary valueForKey:@"1879"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Target Painting" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* signatureRadiusBonusAttribute = [type.attributesDictionary valueForKey:@"554"];
			if (signatureRadiusBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 signatureRadiusBonusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.0f %%", signatureRadiusBonusAttribute.value], @"value",
								 signatureRadiusBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* targetPaintRangeAttribute = [type.attributesDictionary valueForKey:@"941"];
			if (targetPaintRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Optimal Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) targetPaintRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* targetPaintFalloffAttribute = [type.attributesDictionary valueForKey:@"954"];
			if (targetPaintFalloffAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Accuracy Falloff", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) targetPaintFalloffAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_23.png", @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* targetPaintDurationAttribute = [type.attributesDictionary valueForKey:@"945"];
			if (targetPaintDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", targetPaintDurationAttribute.value / 1000], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* targetPaintChanceAttribute = [type.attributesDictionary valueForKey:@"935"];
			if (targetPaintChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", targetPaintChanceAttribute.value * 100], @"value",
								 targetPaintChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		//Tracking Disruption
		if ([type.effectsDictionary valueForKey:@"1877"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Tracking Disruption" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* trackingDisruptMultiplierAttribute = [type.attributesDictionary valueForKey:@"948"];
			if (trackingDisruptMultiplierAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Tracking Speed Bonus", @"title",
								 [NSString stringWithFormat:@"%.0f %%", (trackingDisruptMultiplierAttribute.value - 1) * 100], @"value",
								 @"Icons/icon22_22.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptRangeAttribute = [type.attributesDictionary valueForKey:@"940"];
			if (trackingDisruptRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Optimal Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) trackingDisruptRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptFalloffAttribute = [type.attributesDictionary valueForKey:@"951"];
			if (trackingDisruptFalloffAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Accuracy Falloff", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) trackingDisruptFalloffAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_23.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptDurationAttribute = [type.attributesDictionary valueForKey:@"944"];
			if (trackingDisruptDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", trackingDisruptDurationAttribute.value / 1000], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* trackingDisruptChanceAttribute = [type.attributesDictionary valueForKey:@"933"];
			if (trackingDisruptChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", trackingDisruptChanceAttribute.value * 100], @"value",
								 trackingDisruptChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}		
		
		//Sensor Dampening
		if ([type.effectsDictionary valueForKey:@"1878"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Sensor Dampening" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* maxTargetRangeMultiplierAttribute = [type.attributesDictionary valueForKey:@"237"];
			if (maxTargetRangeMultiplierAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Max Targeting Range Bonus", @"title", 
								 [NSString stringWithFormat:@"%.0f %%", (maxTargetRangeMultiplierAttribute.value - 1) * 100], @"value",
								 maxTargetRangeMultiplierAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* scanResolutionMultiplierAttribute = [type.attributesDictionary valueForKey:@"565"];
			if (scanResolutionMultiplierAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Scan Resolution Bonus", @"title", 
								 [NSString stringWithFormat:@"%.0f %%", (scanResolutionMultiplierAttribute.value - 1) * 100], @"value",
								 scanResolutionMultiplierAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* sensorDampenRangeAttribute = [type.attributesDictionary valueForKey:@"938"];
			if (sensorDampenRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Optimal Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) sensorDampenRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenFalloffAttribute = [type.attributesDictionary valueForKey:@"950"];
			if (sensorDampenFalloffAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Accuracy falloff", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) sensorDampenFalloffAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_23.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenDurationAttribute = [type.attributesDictionary valueForKey:@"943"];
			if (sensorDampenDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", sensorDampenDurationAttribute.value / 1000], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* sensorDampenChanceAttribute = [type.attributesDictionary valueForKey:@"932"];
			if (sensorDampenChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", sensorDampenChanceAttribute.value * 100], @"value",
								 sensorDampenChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		//ECM Jamming
		if ([type.effectsDictionary valueForKey:@"1871"] || [type.effectsDictionary valueForKey:@"1752"] || [type.effectsDictionary valueForKey:@"3710"] || [type.effectsDictionary valueForKey:@"4656"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"ECM Jamming" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* scanGravimetricStrengthBonusAttribute = [type.attributesDictionary valueForKey:@"238"];
			if (scanGravimetricStrengthBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 scanGravimetricStrengthBonusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.2f", scanGravimetricStrengthBonusAttribute.value], @"value",
								 scanGravimetricStrengthBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* scanLadarStrengthBonusAttribute = [type.attributesDictionary valueForKey:@"239"];
			if (scanLadarStrengthBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 scanLadarStrengthBonusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.2f", scanLadarStrengthBonusAttribute.value], @"value",
								 scanLadarStrengthBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* scanMagnetometricStrengthBonusAttribute = [type.attributesDictionary valueForKey:@"240"];
			if (scanMagnetometricStrengthBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 scanMagnetometricStrengthBonusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.2f", scanMagnetometricStrengthBonusAttribute.value], @"value",
								 scanMagnetometricStrengthBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* scanRadarStrengthBonusAttribute = [type.attributesDictionary valueForKey:@"241"];
			if (scanLadarStrengthBonusAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 scanRadarStrengthBonusAttribute.attribute.displayName, @"title",
								 [NSString stringWithFormat:@"%.2f", scanRadarStrengthBonusAttribute.value], @"value",
								 scanRadarStrengthBonusAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}

			EVEDBDgmTypeAttribute* targetJamRangeAttribute = [type.attributesDictionary valueForKey:@"936"];
			if (targetJamRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Optimal Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) targetJamRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* targetJamFalloffAttribute = [type.attributesDictionary valueForKey:@"953"];
			if (targetJamFalloffAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Accuracy falloff", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) targetJamFalloffAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_23.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* targetJamDurationAttribute = [type.attributesDictionary valueForKey:@"929"];
			if (targetJamDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", targetJamDurationAttribute.value / 1000], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* targetJamChanceAttribute = [type.attributesDictionary valueForKey:@"930"];
			if (targetJamChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", targetJamChanceAttribute.value * 100], @"value",
								 targetJamChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}

		//Energy Vampire
		if ([type.effectsDictionary valueForKey:@"1872"]) {
			section = [NSMutableDictionary dictionary];
			rows = [NSMutableArray array];
			[section setValue:@"Energy Vampire" forKey:@"name"];
			[section setValue:rows forKey:@"rows"];
			
			EVEDBDgmTypeAttribute* capacitorDrainAmountAttribute = [type.attributesDictionary valueForKey:@"946"];
			if (!capacitorDrainAmountAttribute)
				capacitorDrainAmountAttribute = [type.attributesDictionary valueForKey:@"90"];
			
			EVEDBDgmTypeAttribute* capacitorDrainDurationAttribute = [type.attributesDictionary valueForKey:@"942"];
			if (capacitorDrainAmountAttribute.value > 0) {
				NSString* value;
				if (capacitorDrainDurationAttribute) {
					value = [NSString stringWithFormat:@"%@ GJ (%.2f GJ/s)",
							 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:(NSInteger) capacitorDrainAmountAttribute.value] numberStyle:NSNumberFormatterDecimalStyle],
							 capacitorDrainAmountAttribute.value / (capacitorDrainDurationAttribute.value / 1000)];

				}
				else {
					value = [NSString stringWithFormat:@"%@ GJ", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:(NSInteger) capacitorDrainAmountAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]];
				}
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Amount", @"title", 
								 value, @"value",
								 @"Icons/icon22_08.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* capacitorDrainRangeAttribute = [type.attributesDictionary valueForKey:@"937"];
			if (capacitorDrainRangeAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Optimal Range", @"title",
								 [NSString stringWithFormat:@"%@ m", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:(NSInteger) capacitorDrainRangeAttribute.value] numberStyle:NSNumberFormatterDecimalStyle]], @"value",
								 @"Icons/icon22_15.png", @"icon",
								 nil]];
			}
			
			if (capacitorDrainDurationAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Duration", @"title",
								 [NSString stringWithFormat:@"%.2f s", capacitorDrainDurationAttribute.value / 1000], @"value",
								 @"Icons/icon22_16.png", @"icon",
								 nil]];
			}
			
			EVEDBDgmTypeAttribute* capacitorDrainChanceAttribute = [type.attributesDictionary valueForKey:@"931"];
			if (capacitorDrainChanceAttribute) {
				[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:0], @"cellType", 
								 @"Chance", @"title",
								 [NSString stringWithFormat:@"%.0f %%", capacitorDrainChanceAttribute.value * 100], @"value",
								 capacitorDrainChanceAttribute.attribute.icon.iconImageName, @"icon",
								 nil]];
			}
			
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		[self.attributesTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		[pool release];
	}];
}

- (void) loadBlueprintAttributes {
	[[EUOperationQueue sharedQueue] addOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		EVEAccount *account = [EVEAccount currentAccount];
		[account updateSkillpoints];
		
		NSMutableArray *rows = [NSMutableArray array];
		NSMutableDictionary *section = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Blueprint", @"name", rows, @"rows", nil];
		EVEDBInvType* productType = self.type.blueprintType.productType;
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:5], @"cellType",
						 @"Product", @"title",
						 [productType typeName], @"value",
						 [productType typeSmallImageName], @"icon",
						 productType, @"type",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Waste Factor", @"title",
						 [NSString stringWithFormat:@"%d %%", self.type.blueprintType.wasteFactor], @"value",
						 productType, @"type",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Production Limit", @"title",
						 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:self.type.blueprintType.maxProductionLimit] numberStyle:NSNumberFormatterDecimalStyle], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Productivity Modifier", @"title",
						 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:self.type.blueprintType.productivityModifier] numberStyle:NSNumberFormatterDecimalStyle], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Material Modifier", @"title",
						 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:self.type.blueprintType.materialModifier] numberStyle:NSNumberFormatterDecimalStyle], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Manufacturing Time", @"title",
						 [NSString stringWithTimeLeft:self.type.blueprintType.productionTime], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Research Manufacturing Time", @"title",
						 [NSString stringWithTimeLeft:self.type.blueprintType.researchProductivityTime], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Research Material Time", @"title",
						 [NSString stringWithTimeLeft:self.type.blueprintType.researchMaterialTime], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Research Copy Time", @"title",
						 [NSString stringWithTimeLeft:self.type.blueprintType.researchCopyTime], @"value",
						 nil]];
		[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithInteger:0], @"cellType",
						 @"Research Tech Time", @"title",
						 [NSString stringWithTimeLeft:self.type.blueprintType.researchTechTime], @"value",
						 nil]];
		[sections addObject:section];


		
		for (EVEDBInvTypeAttributeCategory *category in type.attributeCategories) {
			NSMutableDictionary *section = [NSMutableDictionary dictionary];
			NSMutableArray *rows = [NSMutableArray array];
			
			if (category.categoryID == 8 && trainingTime > 0) {
				NSString *name = [NSString stringWithFormat:@"%@ (%@)", category.categoryName, [NSString stringWithTimeLeft:trainingTime]];
				[section setValue:name forKey:@"name"];
			}
			else
				[section setValue:category.categoryID == 9 ? @"Other" : category.categoryName
						   forKey:@"name"];
			
			[section setValue:rows forKey:@"rows"];
			
			for (EVEDBDgmTypeAttribute *attribute in category.publishedAttributes) {
				
				NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInteger:0], @"cellType",
											attribute.attribute.displayName, @"title",
											nil];
				NSNumber *value = [NSNumber numberWithFloat:attribute.value];
				NSString *unit = attribute.attribute.unit.displayName;
				[row setValue:[NSString stringWithFormat:@"%@ %@",
							   [NSNumberFormatter localizedStringFromNumber:value numberStyle:NSNumberFormatterDecimalStyle],
							   unit ? unit : @""]
					   forKey:@"value"];
				if (attribute.attribute.icon.iconImageName)
					[row setValue:attribute.attribute.icon.iconImageName forKey:@"icon"];
				[rows addObject:row];
			}
			if (rows.count > 0)
				[sections addObject:section];
		}
		
		NSArray* activities = [[self.type.blueprintType activities] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"activityID" ascending:YES]]];
		for (EVEDBRamActivity* activity in activities) {
			NSArray* requiredSkills = [self.type.blueprintType requiredSkillsForActivity:activity.activityID];
			TrainingQueue* requiredSkillsQueue = [TrainingQueue trainingQueueWithRequiredSkills:requiredSkills];
			NSTimeInterval queueTrainingTime = [requiredSkillsQueue trainingTime];
			
			NSMutableArray *rows = [NSMutableArray array];
			NSMutableDictionary *section = [NSMutableDictionary dictionaryWithObjectsAndKeys:rows, @"rows", nil];
			
			if (queueTrainingTime > 0) {
				NSString *name = [NSString stringWithFormat:@"%@ - Skills (%@)", activity.activityName, [NSString stringWithTimeLeft:queueTrainingTime]];
				[section setValue:name forKey:@"name"];
			}
			else {
				NSString *name = [NSString stringWithFormat:@"%@ - Skills", activity.activityName];
				[section setValue:name forKey:@"name"];
			}

												   
			if (requiredSkillsQueue.skills.count && account && account.skillPlan) {
				NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInteger:4], @"cellType",
											@"Add required skills to training plan", @"title",
											[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:requiredSkillsQueue.trainingTime]], @"value",
											requiredSkillsQueue, @"trainingQueue",
											@"Icons/icon50_13.png", @"icon",
											nil];
				[rows addObject:row];
			}


			for (EVEDBInvTypeRequiredSkill* skill in requiredSkills) {
				SkillTree *skillTree = [SkillTree skillTreeWithRootSkill:skill skillLevel:skill.requiredLevel];
				for (SkillTreeItem *skill in skillTree.skills) {
					NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInteger:1], @"cellType",
												[NSString stringWithFormat:@"%@ %@", skill.typeName, [skill romanSkillLevel]], @"value",
												skill, @"type",
												nil];
					switch (skill.skillAvailability) {
						case SkillTreeItemAvailabilityLearned:
							[row setValue:@"Icons/icon38_193.png" forKey:@"icon"];
							break;
						case SkillTreeItemAvailabilityNotLearned:
							[row setValue:@"Icons/icon38_194.png" forKey:@"icon"];
							break;
						case SkillTreeItemAvailabilityLowLevel:
							[row setValue:@"Icons/icon38_195.png" forKey:@"icon"];
							break;
						default:
							break;
					}
					[rows addObject:row];
				}
			}
			if (rows.count > 0)
				[sections addObject:section];

			rows = [NSMutableArray array];
			section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					   [NSString stringWithFormat:@"%@ - Material / Mineral", activity.activityName], @"name", rows, @"rows", nil];

			for (id requirement in [self.type.blueprintType requiredMaterialsForActivity:activity.activityID]) {
				if ([requirement isKindOfClass:[EVEDBRamTypeRequirement class]]) {
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:5], @"cellType",
									 [requirement requiredType].typeName, @"title",
									 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:[requirement quantity]] numberStyle:NSNumberFormatterDecimalStyle], @"value",
									 [[requirement requiredType] typeSmallImageName], @"icon",
									 [requirement requiredType], @"type",
									 nil]];
				}
				else {
					EVEDBInvTypeMaterial* material = requirement;
					float waste = self.type.blueprintType.wasteFactor / 100.0;
					NSInteger quantity = material.quantity * (1.0 + waste);
					NSInteger perfect = material.quantity;
					
					NSInteger materialLevel  = quantity * 2.0 * (waste / (1.0 + waste)) - 1;
					NSString* value;
					if (materialLevel > 0)
						value = [NSString stringWithFormat:@"%@ (%@ at ME: %@)",
								 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:quantity] numberStyle:NSNumberFormatterDecimalStyle],
								 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:perfect] numberStyle:NSNumberFormatterDecimalStyle],
								 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:materialLevel] numberStyle:NSNumberFormatterDecimalStyle]];
					else
						value = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:quantity] numberStyle:NSNumberFormatterDecimalStyle];
					[rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:5], @"cellType",
									 material.materialType.typeName, @"title",
									 value, @"value",
									 [material.materialType typeSmallImageName], @"icon",
									 material.materialType, @"type",
									 nil]];
				}
			}

			if (rows.count > 0)
				[sections addObject:section];
		}
		
		[self.attributesTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		[pool release];
	}];
}

@end
