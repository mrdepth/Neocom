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
#import "NCDatabase.h"
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
@property (nonatomic, assign) BOOL needsLayout;

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

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account || account.accountType == NCAccountTypeCorporate) {
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
										 [self didFinishLoadData:data withCacheDate:data.characterSheet.cacheDate expireDate:data.characterSheet.cacheExpireDate];
									 }
								 }
							 }];
}

- (void) update {
	[super update];
	NCCharacterSheetViewControllerData* data = self.data;
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
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d years", nil), (int32_t) dateComponents.year]];
		if (dateComponents.month)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d months", nil), (int32_t) dateComponents.month]];
		if (dateComponents.day)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"%d days", nil), (int32_t) dateComponents.day]];
		self.corporationTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Member for %@", nil), [components componentsJoinedByString:@", "]];
		
		if (characterInfo.allianceDate) {
			dateComponents = [calendaer components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
															fromDate:characterInfo.allianceDate
															  toDate:characterInfo.currentTime
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
		
		NCDBMapSolarSystem* solarSystem = characterInfo.lastKnownLocation ? [NCDBMapSolarSystem mapSolarSystemWithName:characterInfo.lastKnownLocation] : nil;
		
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
		
		self.cloneLabel.text = characterSheet.cloneName	? [NSString stringWithFormat:@"%@ (%@)", characterSheet.cloneName, [NSString shortStringWithFloat:characterSheet.cloneSkillPoints unit:@"SP"]] : nil;
		
		self.skillsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skills)", nil),
								 [NSString shortStringWithFloat:characterInfo.skillPoints unit:@"SP"],
								 [NSNumberFormatter neocomLocalizedStringFromNumber:@(characterSheet.skills.count)]];
		self.cloneLabel.textColor = characterInfo.skillPoints > characterSheet.cloneSkillPoints ? [UIColor redColor] : [UIColor greenColor];

		if (skillQueue) {
			NSString *text;
			UIColor *color = nil;
			if (skillQueue.skillQueue.count > 0) {
				NSTimeInterval timeLeft = [skillQueue timeLeft];
				if (timeLeft > 3600 * 24)
					color = [UIColor greenColor];
				else
					color = [UIColor yellowColor];
				text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], (int32_t) skillQueue.skillQueue.count];

				EVESkillQueueItem* item = skillQueue.skillQueue[0];
				NCDBInvType* type = [NCDBInvType invTypeWithTypeID:item.typeID];
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
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd"];
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
	
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSManagedObjectContext* context = [NSThread isMainThread] ? database.managedObjectContext : database.backgroundManagedObjectContext;
	__block NCDBInvType* charismaEnhancer = nil;
	__block NCDBInvType* intelligenceEnhancer = nil;
	__block NCDBInvType* memoryEnhancer = nil;
	__block NCDBInvType* perceptionEnhancer = nil;
	__block NCDBInvType* willpowerEnhancer = nil;

	[context performBlockAndWait:^{
		for (EVECharacterSheetImplant* implant in characterSheet.implants) {
			NCDBInvType* type = [NCDBInvType invTypeWithTypeID:implant.typeID];
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
	}];
	
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
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}


@end
