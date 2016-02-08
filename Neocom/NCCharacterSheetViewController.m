//
//  NCCharacterSheetViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCharacterSheetViewController.h"
#import "NCStorage.h"
#import <EVEAPI/EVEAPI.h>
#import "NSNumberFormatter+Neocom.h"
#import "UIImageView+URL.h"
#import "NSString+Neocom.h"
#import "NCDatabase.h"
#import "UIColor+Neocom.h"
#import "NCLocationsManager.h"
#import "NCDefaultTableViewCell.h"
#import <objc/runtime.h>
#import "NCDatabaseTypeInfoViewController.h"


@interface NCCharacterSheetViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVECharacterInfo* characterInfo;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@end

@implementation NCCharacterSheetViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.characterSheet = [aDecoder decodeObjectForKey:@"characterSheet"];
		if (![self.characterSheet isKindOfClass:[EVECharacterSheet class]])
			self.characterSheet = nil;
		
		self.characterInfo = [aDecoder decodeObjectForKey:@"characterInfo"];
		if (![self.characterInfo isKindOfClass:[EVECharacterInfo class]])
			self.characterInfo = nil;
		
		self.accountStatus = [aDecoder decodeObjectForKey:@"accountStatus"];
		if (![self.accountStatus isKindOfClass:[EVEAccountStatus class]])
			self.accountStatus = nil;
		
		self.skillQueue = [aDecoder decodeObjectForKey:@"skillQueue"];
		if (![self.skillQueue isKindOfClass:[EVESkillQueue class]])
			self.skillQueue = nil;

	}
	return self;
}


- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.characterSheet)
		[aCoder encodeObject:self.characterSheet forKey:@"characterSheet"];
	if (self.characterInfo)
		[aCoder encodeObject:self.characterInfo forKey:@"characterInfo"];
	if (self.accountStatus)
		[aCoder encodeObject:self.accountStatus forKey:@"accountStatus"];
	if (self.skillQueue)
		[aCoder encodeObject:self.skillQueue forKey:@"skillQueue"];
}

@end

@interface NCCharacterSheetViewControllerJumpClone : NSObject
@property (nonatomic, strong) EVECharacterSheetJumpClone* jumpClone;
@property (nonatomic, strong) NSArray* implants;
@property (nonatomic, strong) NCLocationsManagerItem* location;
@end

@implementation NCCharacterSheetViewControllerJumpClone
@end

@interface NCCharacterSheetViewController ()
@property (nonatomic, assign) BOOL needsLayout;
@property (nonatomic, strong) NSArray* jumpClones;
@property (nonatomic, strong) NCAccount* account;
- (void) loadJumpClones;

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
	self.tableHeaderView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	self.tableView.tableHeaderView = nil;
	self.account = [NCAccount currentAccount];
	// Do any additional setup after loading the view.
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		if (self.needsLayout) {
			if (self.tableView.tableHeaderView) {
				[self.tableHeaderView setNeedsLayout];
				[self.tableHeaderView layoutIfNeeded];
				CGRect frame = self.tableHeaderView.frame;
				if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
					frame.size.height = [self.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
				else
					frame.size.height = [self.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:999 verticalFittingPriority:1].height;

				if (!CGRectEqualToRect(self.tableHeaderView.frame, frame)) {
					self.tableHeaderView.frame = frame;
					self.tableView.tableHeaderView = self.tableHeaderView;
				}
			}
			self.needsLayout = NO;
		}
	});
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.needsLayout = YES;
	[self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		return [sender object] != nil;
	}
	else
		return YES;
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.jumpClones.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCCharacterSheetViewControllerJumpClone* jumpClone = self.jumpClones[section];
	return MAX(jumpClone.implants.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCCharacterSheetViewControllerJumpClone* jumpClone = self.jumpClones[section];
	NSString* location = jumpClone.location.name.length > 0 ? jumpClone.location.name : NSLocalizedString(@"Unknown Location", nil);
	NSString* name = jumpClone.jumpClone.cloneName.length > 0 ? jumpClone.jumpClone.cloneName : NSLocalizedString(@"Jump Clone", nil);
	return [NSString stringWithFormat:@"%@ / %@", name, location];
}


#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:5];
	
	[account.managedObjectContext performBlock:^{
		if (account.accountType == NCAccountTypeCharacter) {
			EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
			[account reloadWithCachePolicy:cachePolicy completionBlock:^(NSError *error) {
				progress.completedUnitCount++;
				
				NCCharacterSheetViewControllerData* data = [NCCharacterSheetViewControllerData new];

				dispatch_group_t finishDispatchGroup = dispatch_group_create();
				
				dispatch_group_enter(finishDispatchGroup);
				[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					if (error)
						lastError = error;
					data.characterSheet = characterSheet;
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
					dispatch_group_leave(finishDispatchGroup);
				}];
				
				dispatch_group_enter(finishDispatchGroup);
				[account loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error) {
					data.skillQueue = skillQueue;
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
					dispatch_group_leave(finishDispatchGroup);
				}];
				
				dispatch_group_enter(finishDispatchGroup);
				[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
					data.characterInfo = characterInfo;
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
					dispatch_group_leave(finishDispatchGroup);
				}];
				
				dispatch_group_enter(finishDispatchGroup);
				[api accountStatusWithCompletionBlock:^(EVEAccountStatus *result, NSError *error) {
					data.accountStatus = result;
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
					dispatch_group_leave(finishDispatchGroup);
				} progressBlock:nil];

				
				dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
					[self saveCacheData:data cacheDate:[NSDate date] expireDate:[data.characterSheet.eveapi localTimeWithServerTime:data.characterSheet.eveapi.cachedUntil]];
					completionBlock(lastError);
				});
			} progressBlock:nil];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(nil);
			});
		}
	}];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	NCCharacterSheetViewControllerJumpClone* jumpClone = self.jumpClones[indexPath.section];
	if (indexPath.row < jumpClone.implants.count) {
		EVECharacterSheetJumpCloneImplant* implant = jumpClone.implants[indexPath.row];
		NCDBInvType* type = objc_getAssociatedObject(implant, @"type");
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:implant.typeID];
			objc_setAssociatedObject(implant, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
		cell.titleLabel.text = implant.typeName;
		cell.iconView.image = type.icon.image.image;
		cell.object = type;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		cell.titleLabel.text = nil;
		cell.subtitleLabel.text = NSLocalizedString(@"No Implants", nil);
		cell.iconView.image = nil;
		cell.object = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCCharacterSheetViewControllerData* data = self.cacheData;
	self.characterImageView.image = nil;
	self.corporationImageView.image = nil;
	self.allianceImageView.image = nil;

	EVECharacterInfo* characterInfo = data.characterInfo;
	EVECharacterSheet* characterSheet = data.characterSheet;
	EVEAccountStatus* accountStatus = data.accountStatus;
	EVESkillQueue* skillQueue = data.skillQueue;
	
	if (!characterInfo)
		self.tableView.tableHeaderView = nil;
	else
		self.tableView.tableHeaderView = self.tableHeaderView;
	
	[self.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:characterSheet.characterID size:EVEImageSizeRetina256 error:nil]];
	
	[self.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:characterSheet.corporationID size:EVEImageSizeRetina32 error:nil]];
	if (characterSheet.allianceID)
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:characterSheet.allianceID size:EVEImageSizeRetina32 error:nil]];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	[dateFormatter setDateFormat:@"yyyy.MM.dd"];
	

	NSMutableAttributedString* characterName = [[NSMutableAttributedString alloc] initWithString:characterSheet.name attributes:nil];
	[characterName appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [dateFormatter stringFromDate:characterSheet.DoB]] attributes:@{NSFontAttributeName: [self.characterNameLabel.font fontWithSize:self.characterNameLabel.font.pointSize * 0.5],
																																														//(__bridge NSString*) (kCTSuperscriptAttributeName): @(-1),
																																														NSForegroundColorAttributeName: [UIColor lightTextColor]}]];
	self.characterNameLabel.attributedText = characterName;
	self.corporationNameLabel.text = characterSheet.corporationName;
	self.allianceNameLabel.text = characterSheet.allianceName;
	
	self.bloodlineLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", characterSheet.race, characterSheet.bloodLine, characterSheet.ancestry];
	
	if (characterInfo) {
		self.securityStatusLabel.text = [NSString stringWithFormat:@"%.1f", characterInfo.securityStatus];
		self.securityStatusLabel.textColor = [UIColor colorWithPlayerSecurityStatus:characterInfo.securityStatus];
		
		NSCalendar* calendaer = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		NSDateComponents* dateComponents = [calendaer components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
														fromDate:characterInfo.corporationDate
														  toDate:characterInfo.eveapi.currentTime
														 options:0];
		NSMutableArray* components = [NSMutableArray new];
		if (dateComponents.year)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d years", nil), (int32_t) dateComponents.year]];
		if (dateComponents.month)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d months", nil), (int32_t) dateComponents.month]];
		if (dateComponents.day)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d days", nil), (int32_t) dateComponents.day]];
		self.corporationTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Member for %@", nil), [components componentsJoinedByString:@", "]];
		
		if (characterInfo.allianceDate) {
			dateComponents = [calendaer components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
															fromDate:characterInfo.allianceDate
															  toDate:characterInfo.eveapi.currentTime
															 options:0];
			[components removeAllObjects];
			if (dateComponents.year)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d years", nil), (int32_t) dateComponents.year]];
			if (dateComponents.month)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d months", nil), (int32_t) dateComponents.month]];
			if (dateComponents.day)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d days", nil), (int32_t) dateComponents.day]];
			self.allianceTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Member for %@", nil), [components componentsJoinedByString:@", "]];
		}
		else
			self.allianceTimeLabel.text = nil;
		
		NCDBMapSolarSystem* solarSystem = characterInfo.lastKnownLocation ? [self.databaseManagedObjectContext mapSolarSystemWithName:characterInfo.lastKnownLocation] : nil;
		
		if (solarSystem) {
			NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.security];
			NSString* s = [NSString stringWithFormat:@"%@ %@ / %@ / %@", ss, solarSystem.solarSystemName, solarSystem.constellation.constellationName, solarSystem.constellation.region.regionName];
			NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
			[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.security] range:NSMakeRange(0, ss.length)];
			self.locationLabel.attributedText = title;
		}
		else
			self.locationLabel.text = characterInfo.lastKnownLocation;
		
		self.shipLabel.text = characterInfo.shipTypeName;
		
		self.skillsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skills)", nil),
								 [NSString shortStringWithFloat:characterInfo.skillPoints unit:@"SP"],
								 [NSNumberFormatter neocomLocalizedStringFromNumber:@(characterSheet.skills.count)]];

		if (skillQueue) {
			NSString *text;
			UIColor *color = nil;
			NSTimeInterval timeLeft = [skillQueue timeLeft];
			if (timeLeft > 0) {
				if (timeLeft > 3600 * 24)
					color = [UIColor greenColor];
				else
					color = [UIColor yellowColor];
				text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], (int32_t) skillQueue.skillQueue.count];

				EVESkillQueueItem* item = skillQueue.skillQueue[0];
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				self.currentSkillLabel.text = [NSString stringWithFormat:NSLocalizedString(@"> %@ Level %d", nil), type.typeName, (int32_t) item.level];
			}
			else {
				text = NSLocalizedString(@"Training queue is inactive", nil);
				color = [UIColor redColor];
				self.currentSkillLabel.text = nil;
			}
			self.skillQueueLabel.text = text;
			self.skillQueueLabel.textColor = color;
			
		}
		else {
			self.skillQueueLabel.text = nil;
			self.currentSkillLabel.text = nil;
		}
	}
	else {
		self.locationLabel.text = nil;
		self.shipLabel.text = nil;
		
		self.skillsLabel.text = nil;
		self.skillQueueLabel.text = nil;
		self.currentSkillLabel.text = nil;
	}
	
	self.balanceLabel.text = [NSString shortStringWithFloat:characterSheet.balance unit:NSLocalizedString(@"ISK", nil)];
	
	if (accountStatus) {
		UIColor *color;
		int days = [accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
		if (days < 0)
			days = 0;
		if (days > 7)
			color = [UIColor greenColor];
		else if (days == 0)
			color = [UIColor redColor];
		else
			color = [UIColor yellowColor];
		self.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d days remaining)", nil), [dateFormatter stringFromDate:accountStatus.paidUntil], (int32_t) days];
		self.subscriptionLabel.textColor = color;
	}
	else {
		self.subscriptionLabel.text = nil;
	}
	
	NCDBInvType* charismaEnhancer = nil;
	NCDBInvType* intelligenceEnhancer = nil;
	NCDBInvType* memoryEnhancer = nil;
	NCDBInvType* perceptionEnhancer = nil;
	NCDBInvType* willpowerEnhancer = nil;

	for (EVECharacterSheetImplant* implant in characterSheet.implants) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:implant.typeID];
		if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[(NCDBDgmTypeAttribute*) @(NCCharismaBonusAttributeID)] value] > 0)
			charismaEnhancer = type;
		else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value] > 0)
			intelligenceEnhancer = type;
		else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCMemoryBonusAttributeID)] value] > 0)
			memoryEnhancer = type;
		else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCPerceptionBonusAttributeID)] value] > 0)
			perceptionEnhancer = type;
		else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCWillpowerBonusAttributeID)] value] > 0)
			willpowerEnhancer = type;
	}
	
	if (intelligenceEnhancer) {
		int32_t value = [(NCDBDgmTypeAttribute*) intelligenceEnhancer.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value];
		self.intelligenceLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									   characterSheet.attributes.intelligence + value,
									   characterSheet.attributes.intelligence,
									   value];
	}
	else
		self.intelligenceLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.intelligence];
	
	if (memoryEnhancer) {
		int32_t value = [(NCDBDgmTypeAttribute*) memoryEnhancer.attributesDictionary[@(NCMemoryBonusAttributeID)] value];
		self.memoryLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
								 characterSheet.attributes.memory + value,
								 characterSheet.attributes.memory,
								 value];
	}
	else
		self.memoryLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.memory];
	
	
	if (perceptionEnhancer) {
		int32_t value = [(NCDBDgmTypeAttribute*) perceptionEnhancer.attributesDictionary[@(NCPerceptionBonusAttributeID)] value];
		self.perceptionLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									 characterSheet.attributes.perception + value,
									 characterSheet.attributes.perception,
									 value];
	}
	else
		self.perceptionLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.perception];
	
	if (willpowerEnhancer) {
		int32_t value = [(NCDBDgmTypeAttribute*) willpowerEnhancer.attributesDictionary[@(NCWillpowerBonusAttributeID)] value];
		self.willpowerLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									characterSheet.attributes.willpower + value,
									characterSheet.attributes.willpower,
									value];
	}
	else
		self.willpowerLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.willpower];
	
	if (charismaEnhancer) {
		int32_t value = [(NCDBDgmTypeAttribute*) charismaEnhancer.attributesDictionary[@(NCCharismaBonusAttributeID)] value];
		self.charismaLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
								   characterSheet.attributes.charisma + value,
								   characterSheet.attributes.charisma,
								   value];
	}
	else
		self.charismaLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.charisma];
	
	self.needsLayout = YES;
	[self.view setNeedsLayout];
	
	[self loadJumpClones];
	
	completionBlock();
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

#pragma mark - Private

- (void) loadJumpClones {
	NCCharacterSheetViewControllerData* data = self.cacheData;

	NSMutableArray* jumpClones = [NSMutableArray new];
	NSMutableSet* locationIDs = [NSMutableSet new];
	for (EVECharacterSheetJumpClone* eveClone in data.characterSheet.jumpClones) {
		NCCharacterSheetViewControllerJumpClone* jumpClone = [NCCharacterSheetViewControllerJumpClone new];
		jumpClone.jumpClone = eveClone;
		jumpClone.implants = [data.characterSheet.jumpCloneImplants filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"jumpCloneID == %d", eveClone.jumpCloneID]];
		
		[locationIDs addObject:@(eveClone.locationID)];
		[jumpClones addObject:jumpClone];
	}
	if (locationIDs.count > 0) {
		[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:[locationIDs allObjects] completionBlock:^(NSDictionary *locationsNames) {
			dispatch_async(dispatch_get_main_queue(), ^{
				for (NCCharacterSheetViewControllerJumpClone* jumpClone in jumpClones)
					jumpClone.location = locationsNames[@(jumpClone.jumpClone.locationID)];
				[self.tableView reloadData];
			});
		}];
	}
	else
		[self.tableView reloadData];
	self.jumpClones = jumpClones;
}

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

@end
