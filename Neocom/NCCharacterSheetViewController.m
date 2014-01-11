//
//  NCCharacterSheetViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCharacterSheetViewController.h"
#import "NCStorage.h"
#import "EVEOnlineAPI.h"
#import "NSNumberFormatter+Neocom.h"

@interface NCCharacterSheetViewControllerRow : NSObject<NSCoding>
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) UIColor* color;

+ (id) rowWithTitle:(NSString*) title value:(NSString*) value color:(UIColor*) color;
- (id) initWithTitle:(NSString*) title value:(NSString*) value color:(UIColor*) color;
@end

@interface NCCharacterSheetViewControllerSection : NSObject<NSCoding>
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;

+ (id) sectionWithTitle:(NSString*) title rows:(NSArray*) rows;
- (id) initWithTitle:(NSString*) title rows:(NSArray*) rows;
@end

@implementation NCCharacterSheetViewControllerRow

+ (id) rowWithTitle:(NSString*) title value:(NSString*) value color:(UIColor*) color {
	return [[self alloc] initWithTitle:title value:value color:color];
}

- (id) initWithTitle:(NSString*) title value:(NSString*) value color:(UIColor*) color {
	if (self = [super init]) {
		self.title = title;
		self.value = value;
		self.color = color;
	}
	return self;
}



@end

@implementation NCCharacterSheetViewControllerSection

+ (id) sectionWithTitle:(NSString*) title rows:(NSArray*) rows {
	return [[self alloc] initWithTitle:title rows:rows];
}


- (id) initWithTitle:(NSString*) title rows:(NSArray*) rows {
	if (self = [super init]) {
		self.title = title;
		self.rows = rows;
	}
	return self;
}


@end

@interface NCCharacterSheetViewController ()

@end

@implementation NCCharacterSheetViewController

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

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NSMutableArray* sections = [NSMutableArray new];
	NCAccount* account = [NCAccount currentAccount];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVECharacterSheet* characterSheet = [EVECharacterSheet characterSheetWithKeyID:account.apiKey.keyID
																													  vCode:account.apiKey.vCode
																												cachePolicy:cachePolicy
																												characterID:account.characterID
																													  error:&error
																											progressHandler:^(CGFloat progress, BOOL *stop) {
																												if ([task isCancelled])
																													*stop = YES;
																												else
																													task.progress = progress;
																											}];
											 if (characterSheet && ![task isCancelled]) {
												 NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
												 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
												 [dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
												 
												 NSMutableArray* rows = [NSMutableArray new];
												 NCCharacterSheetViewControllerSection* section = [NCCharacterSheetViewControllerSection sectionWithTitle:NSLocalizedString(@"Bloodline", nil)
																																					 rows:rows];
												 
												 NSMutableString* value = [NSMutableString stringWithString:characterSheet.corporationName];
												 if (characterSheet.allianceName)
													 [value appendFormat:@", %@", characterSheet.allianceName];
												 
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:characterSheet.name value:value color:nil]];
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Date of birth", nil) value:[dateFormatter stringFromDate:characterSheet.DoB] color:nil]];
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Race", nil) value:characterSheet.race color:nil]];
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Bloodline", nil) value:characterSheet.bloodLine color:nil]];
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Ancestry", nil) value:characterSheet.ancestry color:nil]];
												 [sections addObject:section];
												 
												 rows = [NSMutableArray new];
												 section = [NCCharacterSheetViewControllerSection sectionWithTitle:NSLocalizedString(@"Attributes", nil) rows:rows];
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
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Intelligence %d (%d + %d)", nil),
																													  characterSheet.attributes.intelligence + intelligenceEnhancer.augmentatorValue,
																													  characterSheet.attributes.intelligence,
																													  intelligenceEnhancer.augmentatorValue]
																											   value:intelligenceEnhancer.augmentatorName
																											   color:nil]];
												 else
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Intelligence %d", nil),
																													  characterSheet.attributes.intelligence]
																											   value:nil
																											   color:nil]];
												 if (memoryEnhancer)
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Memory %d (%d + %d)", nil),
																													  characterSheet.attributes.memory + memoryEnhancer.augmentatorValue,
																													  characterSheet.attributes.memory,
																													  memoryEnhancer.augmentatorValue]
																											   value:memoryEnhancer.augmentatorName
																											   color:nil]];
												 else
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Memory %d", nil),
																													  characterSheet.attributes.memory]
																											   value:nil
																											   color:nil]];
												 
												 if (perceptionEnhancer)
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Perception %d (%d + %d)", nil),
																													  characterSheet.attributes.perception + perceptionEnhancer.augmentatorValue,
																													  characterSheet.attributes.perception,
																													  perceptionEnhancer.augmentatorValue]
																											   value:perceptionEnhancer.augmentatorName
																											   color:nil]];
												 else
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Perception %d", nil),
																													  characterSheet.attributes.perception]
																											   value:nil
																											   color:nil]];
												 

												 if (willpowerEnhancer)
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Willpower %d (%d + %d)", nil),
																													  characterSheet.attributes.willpower + willpowerEnhancer.augmentatorValue,
																													  characterSheet.attributes.willpower,
																													  willpowerEnhancer.augmentatorValue]
																											   value:willpowerEnhancer.augmentatorName
																											   color:nil]];
												 else
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Willpower %d", nil),
																													  characterSheet.attributes.willpower]
																											   value:nil
																											   color:nil]];

												 if (charismaEnhancer)
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Charisma %d (%d + %d)", nil),
																													  characterSheet.attributes.charisma + charismaEnhancer.augmentatorValue,
																													  characterSheet.attributes.charisma,
																													  charismaEnhancer.augmentatorValue]
																											   value:charismaEnhancer.augmentatorName
																											   color:nil]];
												 else
													 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Charisma %d", nil),
																													  characterSheet.attributes.charisma]
																											   value:nil
																											   color:nil]];
												 
												 [sections addObject:section];
												 
												 rows = [NSMutableArray new];
												 section = [NCCharacterSheetViewControllerSection sectionWithTitle:characterSheet.cloneName ? characterSheet.cloneName : NSLocalizedString(@"No clone", nil)
																											  rows:rows];
												 
												 int skillpoints = 0;
												 for (EVECharacterSheetSkill *skill in characterSheet.skills)
													 skillpoints += skill.skillpoints;
												 UIColor* color = skillpoints > characterSheet.cloneSkillPoints ? [UIColor redColor] : [UIColor greenColor];
												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Total skillpoints", nil)
																										   value:[NSNumberFormatter neocomLocalizedStringFromInteger:skillpoints]
																										   color:nil]];

												 [rows addObject:[NCCharacterSheetViewControllerRow rowWithTitle:NSLocalizedString(@"Clone skillpoints", nil)
																										   value:[NSNumberFormatter neocomLocalizedStringFromInteger:characterSheet.cloneSkillPoints]
																										   color:color]];
												 [sections addObject:section];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:sections withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}


@end
