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
#import "UIImageView+URL.h"
#import "NSString+Neocom.h"
#import "EVEDBAPI.h"
#import "UIColor+Neocom.h"

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

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	UIView* header = self.tableView.tableHeaderView;
	CGRect frame = header.frame;
	frame.size.height = CGRectGetMaxY(self.scrollView.frame);
	if (!CGRectEqualToRect(header.frame, frame)) {
		header.frame = frame;
		self.tableView.tableHeaderView = header;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCCharacterSheetViewControllerData* data = [NCCharacterSheetViewControllerData new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 
											 [account reloadWithCachePolicy:cachePolicy
																	  error:&error
															progressHandler:^(CGFloat progress, BOOL *stop) {
																task.progress = (2.0 + progress) / 4.0;
																if (task.isCancelled)
																	*stop = YES;
															}];
											 if ([task isCancelled])
												 return;
											 data.characterSheet = account.characterSheet;
											 data.characterInfo = account.characterInfo;
											 data.skillQueue = account.skillQueue;
											 
											 if ([task isCancelled])
												 return;
											 data.accountStatus = [EVEAccountStatus accountStatusWithKeyID:account.apiKey.keyID
																									 vCode:account.apiKey.vCode
																							   cachePolicy:cachePolicy
																									 error:nil
																						   progressHandler:^(CGFloat progress, BOOL *stop) {
																							   if ([task isCancelled])
																								   *stop = YES;
																							   else
																								   task.progress = (3.0 + progress) / 4.0;
																						   }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) update {
	[super update];
	NCCharacterSheetViewControllerData* data = self.cacheRecord.data;
	self.characterImageView.image = nil;
	self.corporationImageView.image = nil;
	self.allianceImageView.image = nil;

	EVECharacterInfo* characterInfo = data.characterInfo;
	EVECharacterSheet* characterSheet = data.characterSheet;
	EVEAccountStatus* accountStatus = data.accountStatus;
	EVESkillQueue* skillQueue = data.skillQueue;
	
	if (!characterInfo) {
		UIView* header = self.tableView.tableHeaderView;
		CGRect frame = header.frame;
		frame.size.height = 0;
		header.frame = frame;
		self.tableView.tableHeaderView = header;
		self.tableView.tableHeaderView.hidden = YES;
		return;
	}
	else
		self.tableView.tableHeaderView.hidden = NO;

	
	[self.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:characterSheet.characterID size:EVEImageSizeRetina256 error:nil]];
	
	[self.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:characterSheet.corporationID size:EVEImageSizeRetina32 error:nil]];
	if (characterSheet.allianceID)
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:characterSheet.allianceID size:EVEImageSizeRetina32 error:nil]];

	self.characterNameLabel.text = characterSheet.name;
	self.corporationNameLabel.text = characterSheet.corporationName;
	self.allianceNameLabel.text = characterSheet.allianceName;
	
	self.bloodlineLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", characterSheet.race, characterSheet.bloodLine, characterSheet.ancestry];
	
	if (characterInfo) {
		self.securityStatusLabel.text = [NSString stringWithFormat:@"%.1f", characterInfo.securityStatus];
		self.securityStatusLabel.textColor = [UIColor colorWithPlayerSecurityStatus:characterInfo.securityStatus];
		
		NSCalendar* calendaer = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents* dateComponents = [calendaer components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
														fromDate:characterInfo.corporationDate
														  toDate:characterInfo.currentTime
														 options:0];
		NSMutableArray* components = [NSMutableArray new];
		if (dateComponents.year)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d years", nil), dateComponents.year]];
		if (dateComponents.month)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d months", nil), dateComponents.month]];
		if (dateComponents.day)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d days", nil), dateComponents.day]];
		self.corporationTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Member for %@", nil), [components componentsJoinedByString:@", "]];
		
		if (characterInfo.allianceDate) {
			dateComponents = [calendaer components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
															fromDate:characterInfo.allianceDate
															  toDate:characterInfo.currentTime
															 options:0];
			[components removeAllObjects];
			if (dateComponents.year)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d years", nil), dateComponents.year]];
			if (dateComponents.month)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d months", nil), dateComponents.month]];
			if (dateComponents.day)
				[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d days", nil), dateComponents.day]];
			self.allianceTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Member for %@", nil), [components componentsJoinedByString:@", "]];
		}
		
		EVEDBMapSolarSystem* solarSystem = [[EVEDBMapSolarSystem alloc] initWithSQLRequest:[NSString stringWithFormat:@"SELECT * from mapSolarSystems WHERE solarSystemName==\"%@\"", characterInfo.lastKnownLocation]
																					 error:nil];
		if (solarSystem) {
			NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.security];
			NSString* s = [NSString stringWithFormat:@"%@ %@ / %@ / %@", ss, solarSystem.solarSystemName, solarSystem.constellation.constellationName, solarSystem.region.regionName];
			NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
			[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.security] range:NSMakeRange(0, ss.length)];
			self.locationLabel.attributedText = title;
		}
		else
			self.locationLabel.text = characterInfo.lastKnownLocation;
		
		self.shipLabel.text = characterInfo.shipTypeName;
		
		self.cloneLabel.text = characterSheet.cloneName	? [NSString stringWithFormat:@"%@ (%@)", characterSheet.cloneName, [NSString shortStringWithFloat:characterSheet.cloneSkillPoints unit:@"SP"]] : nil;
		
		self.skillsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skills)", nil),
								 [NSString shortStringWithFloat:characterInfo.skillPoints unit:@"SP"],
								 [NSNumberFormatter neocomLocalizedStringFromNumber:@(characterSheet.skills.count)]];
		self.cloneLabel.textColor = characterInfo.skillPoints > characterSheet.cloneSkillPoints ? [UIColor redColor] : [UIColor greenColor];

		if (skillQueue) {
			NSString *text;
			UIColor *color = nil;
			if (skillQueue.skillQueue.count > 0) {
				NSDate *endTime = [[skillQueue.skillQueue lastObject] endTime];
				NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[skillQueue serverTimeWithLocalTime:[NSDate date]]];
				if (timeLeft > 3600 * 24)
					color = [UIColor greenColor];
				else
					color = [UIColor yellowColor];
				text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], skillQueue.skillQueue.count];
			}
			else {
				text = NSLocalizedString(@"Training queue is inactive", nil);
				color = [UIColor redColor];
			}
			self.skillQueueLabel.text = text;
			self.skillQueueLabel.textColor = color;
			
			EVESkillQueueItem* item = skillQueue.skillQueue[0];
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			self.currentSkillLabel.text = [NSString stringWithFormat:NSLocalizedString(@"> %@ Level %d", nil), type.typeName, item.level];
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
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		int days = [accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
		if (days < 0)
			days = 0;
		if (days > 7)
			color = [UIColor greenColor];
		else if (days == 0)
			color = [UIColor redColor];
		else
			color = [UIColor yellowColor];
		self.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d days remaining)", nil), [dateFormatter stringFromDate:accountStatus.paidUntil], days];
		self.subscriptionLabel.textColor = color;
	}
	else {
		self.subscriptionLabel.text = nil;
	}
	
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
		self.intelligenceLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									   characterSheet.attributes.intelligence + intelligenceEnhancer.augmentatorValue,
									   characterSheet.attributes.intelligence,
									   intelligenceEnhancer.augmentatorValue];
	else
		self.intelligenceLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.intelligence];
	
	if (memoryEnhancer)
		self.memoryLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
								 characterSheet.attributes.memory + memoryEnhancer.augmentatorValue,
								 characterSheet.attributes.memory,
								 memoryEnhancer.augmentatorValue];
	else
		self.memoryLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.memory];
	
	
	if (perceptionEnhancer)
		self.perceptionLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									 characterSheet.attributes.perception + perceptionEnhancer.augmentatorValue,
									 characterSheet.attributes.perception,
									 perceptionEnhancer.augmentatorValue];
	else
		self.perceptionLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.perception];
	
	if (willpowerEnhancer)
		self.willpowerLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
									characterSheet.attributes.willpower + willpowerEnhancer.augmentatorValue,
									characterSheet.attributes.willpower,
									willpowerEnhancer.augmentatorValue];
	else
		self.willpowerLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.willpower];
	
	if (charismaEnhancer)
		self.charismaLabel.text = [NSString stringWithFormat:@"%d (%d + %d)",
								   characterSheet.attributes.charisma + charismaEnhancer.augmentatorValue,
								   characterSheet.attributes.charisma,
								   charismaEnhancer.augmentatorValue];
	else
		self.charismaLabel.text = [NSString stringWithFormat:@"%d", characterSheet.attributes.charisma];
	
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}


@end
