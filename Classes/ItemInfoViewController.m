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
	NSMutableString* description = [NSMutableString stringWithString:[[type.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes]];
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
	if (cellType == 0 || cellType == 2 || cellType == 4) {
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
		
		cell.accessoryType = cellType == 2 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		
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

		NSInteger hierarchyLevel = [[row valueForKey:@"skill"] hierarchyLevel];
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
	if (cellType == 1) {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																			  bundle:nil];
		controller.type = [row valueForKey:@"skill"];
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
					
					for (NSDictionary *requirementMap in skillRequirementsMap) {
						if ([[requirementMap valueForKey:SkillTreeRequirementIDKey] integerValue] == attribute.attributeID) {
							EVEDBDgmTypeAttribute *level = [type.attributesDictionary valueForKey:[requirementMap valueForKey:SkillTreeSkillLevelIDKey]];
							SkillTree *skillTree = [SkillTree skillTreeWithRootSkill:skill skillLevel:level.value];
							for (SkillTreeItem *skill in skillTree.skills) {
								NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithInteger:1], @"cellType", 
															[NSString stringWithFormat:@"%@ %@", skill.typeName, [skill romanSkillLevel]], @"value",
															skill, @"skill",
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
					[row setValue:[NSString stringWithFormat:@"%Training time: %@",
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

@end
