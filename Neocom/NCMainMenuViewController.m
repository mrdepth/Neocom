//
//  NCMainMenuViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuViewController.h"
#import "NCStorage.h"
#import "NCTableViewEmptyHeaderView.h"
#import "NCSideMenuViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "NSString+Neocom.h"
#import "NCTableViewCell.h"
#import "EVECentralAPI.h"
#import "NCSplitViewController.h"

#define NCPlexTypeID 29668
#define NCTritaniumTypeID 34
#define NCPyeriteTypeID 35
#define NCMexallonTypeID 36
#define NCIsogenTypeID 37
#define NCNocxiumTypeID 38
#define NCZydrineTypeID 39
#define NCMegacyteTypeID 40
#define NCMorphiteTypeID 11399

#define NCTheForgeRegionID 10000002

#define NCPlexRate (209.94 / 12.0 * 1000000000.0)

@interface NCMainMenuViewController ()
@property (nonatomic, strong) NSArray* allSections;
@property (nonatomic, strong) NSMutableArray* sections;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, strong) EVEServerStatus* serverStatus;
@property (nonatomic, strong) EVECentralMarketStat* marketStat;
@property (nonatomic, readonly) NSString* skillsDetails;
@property (nonatomic, readonly) NSString* skillQueueDetails;
@property (nonatomic, readonly) NSString* mailsDetails;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
- (void) reload;
- (void) onTimer:(NSTimer*) timer;
- (void) updateServerStatus;
- (void) updatePrices;
- (void) updateMarqueeLabel;
- (void) marketPricesMonitorDidChange:(NSNotification*) notification;
@end

@implementation NCMainMenuViewController

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
	
	self.refreshControl = nil;
	[self.tableView registerClass:[NCTableViewEmptyHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewEmptyHeaderView"];
	self.allSections = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];
	[self reload];
	
	self.dateFormatter = [NSDateFormatter new];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	[self.dateFormatter setDateFormat:@"HH:mm:ss"];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(marketPricesMonitorDidChange:) name:NCMarketPricesMonitorDidChangeNotification object:nil];
	
	[super viewWillAppear:animated];
	[self update];
	if (self.serverStatus) {
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
		[self onTimer:self.timer];
	}
	else
		[self updateServerStatus];
	[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[self updateMarqueeLabel];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.timer = nil;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCMarketPricesMonitorDidChangeNotification object:nil];
}

- (void) dealloc {
	self.timer = nil;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NCSplitViewController* splitViewController = (NCSplitViewController*) self.splitViewController;
	[splitViewController.masterPopover dismissPopoverAnimated:YES];
}

- (IBAction)onFacebook:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com/groups/Neocom/"]];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	
	cell.titleLabel.text = row[@"title"];
	cell.iconView.image = [UIImage imageNamed:row[@"image"]];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	if (detailsKeyPath)
		cell.subtitleLabel.text = [self valueForKey:detailsKeyPath];
	else
		cell.subtitleLabel.text = nil;
	
	if (!cell.accessoryView) {
		cell.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 44)];
		cell.accessoryView.hidden = NO;
	}
	return cell;
}

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else
		return [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewEmptyHeaderView"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	NSString* details = nil;
	if (detailsKeyPath)
		details = [self valueForKey:detailsKeyPath];
	if (details) {
		if (details && [details rangeOfString:@"\n"].location != NSNotFound)
			return 56;
		else
			return 42;
	}
	else
		return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return 0;
	else
		return 22;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	[self performSegueWithIdentifier:row[@"segueIdentifier"] sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reload];
}

- (void) didChangeStorage {
	[self reload];
}

- (BOOL) shouldReloadData {
	return YES;
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reload) object:nil];
	NSTimeInterval delay = 0;
	if (self.skillQueue)
		delay = [self.skillQueue.cacheExpireDate timeIntervalSinceNow];
	else if (self.characterSheet)
		delay = [self.characterSheet.cacheExpireDate timeIntervalSinceNow];
	if (delay > 0)
		[self performSelector:@selector(reload) withObject:nil afterDelay:delay];
	else
		[self reload];

	if (self.marketStat.cacheExpireDate)
		delay = [self.marketStat.cacheExpireDate timeIntervalSinceNow];
	if (delay > 0)
		[self performSelector:@selector(updatePrices) withObject:nil afterDelay:delay];
	else
		[self updatePrices];
	[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
}

#pragma mark - Private

- (void) reload {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reload) object:nil];
	NCAccount* account = [NCAccount currentAccount];
	NSInteger apiKeyAccessMask = account.apiKey.apiKeyInfo.key.accessMask;
	NSString* accessMaskKey = account.accountType == NCAccountTypeCorporate ? @"corpAccessMask" : @"charAccessMask" ;
	
	self.sections = [NSMutableArray new];
	for (NSArray* rows in self.allSections) {
		NSMutableArray* section = [NSMutableArray new];
		for (NSDictionary* row in rows) {
			NSInteger accessMask = [[row valueForKey:accessMaskKey] integerValue];
			if ((accessMask & apiKeyAccessMask) == accessMask) {
				[section addObject:row];
			}
		}
		if (section.count > 0)
			[self.sections addObject:section];
	}
	
	[self update];

	__block EVECharacterSheet* characterSheet;
	__block EVESkillQueue* skillQueue;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 characterSheet = account.characterSheet;
											 skillQueue = account.skillQueue;
											 [account.mailBox messages];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.characterSheet = characterSheet;
									 self.skillQueue = skillQueue;
									 [self update];
									 
									 NSTimeInterval delay = 0;
									 if (self.skillQueue)
										delay = [self.skillQueue.cacheExpireDate timeIntervalSinceNow];
									 else if (self.characterSheet)
										 delay = [self.characterSheet.cacheExpireDate timeIntervalSinceNow];
									 if (delay > 0)
										 [self performSelector:@selector(reload) withObject:nil afterDelay:delay];

								 }
							 }];
}

- (NSString*) skillsDetails {
	if (self.characterSheet) {
		NSInteger skillPoints = 0;
		for (EVECharacterSheetSkill* skill in self.characterSheet.skills)
			skillPoints += skill.skillpoints;

		//return [NSString stringWithFormat:NSLocalizedString(@"%@ skillpoints (%d skills)", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:skillPoints], (int32_t) self.characterSheet.skills.count];
		
		return [NSString stringWithFormat:NSLocalizedString(@"%@ skillpoints (%d skills)\n%@ ISK", nil),
				[NSNumberFormatter neocomLocalizedStringFromInteger:skillPoints], (int32_t) self.characterSheet.skills.count,
				[NSString shortStringWithFloat:self.characterSheet.balance unit:NSLocalizedString(@"ISK", nil)]];
	}
	else
		return nil;
}

- (NSString*) skillQueueDetails {
	if (self.skillQueue) {
		EVESkillQueue* skillQueue = self.skillQueue;
		if (skillQueue.skillQueue.count > 0) {
			NSTimeInterval timeLeft = [skillQueue timeLeft];
			return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], (int32_t) skillQueue.skillQueue.count];
		}
		else
			return NSLocalizedString(@"Training queue is inactive", nil);
	}
	return nil;
}

- (NSString*) mailsDetails {
	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		NSInteger numberOfUnreadMessages = account.mailBox.numberOfUnreadMessages;
		if (numberOfUnreadMessages > 0)
			return [NSString stringWithFormat:NSLocalizedString(@"%d unread messages", nil), (int32_t) numberOfUnreadMessages];
	}
	return nil;
}

- (void) onTimer:(NSTimer*) timer {
	if (self.serverStatus) {
		self.serverTimeLabel.text = [self.dateFormatter stringFromDate:[self.serverStatus serverTimeWithLocalTime:[NSDate date]]];
		if ([[self.serverStatus cacheExpireDate] compare:[NSDate date]] == NSOrderedAscending) {
			[self updateServerStatus];
			self.timer = nil;
		}
	}
	else {
		self.timer = nil;
	}
}

- (void) setTimer:(NSTimer *)timer {
	[_timer invalidate];
	_timer = timer;
}

- (void) updateServerStatus {
	__block EVEServerStatus* serverStatus = nil;
	__block NSError* error = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 serverStatus = [EVEServerStatus serverStatusWithCachePolicy:NSURLRequestUseProtocolCachePolicy
																								   error:&error
																						 progressHandler:nil];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 if (serverStatus) {
										 self.serverStatus = serverStatus;
										 self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
										 self.serverStatusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ players online", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:serverStatus.onlinePlayers]];
										 [self onTimer:self.timer];
									 }
									 else {
										 if (error)
											 self.serverStatusLabel.text = [error localizedDescription];
										 else
											 self.serverStatusLabel.text = NSLocalizedString(@"Server offline", nil);
										 [self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:30.];
									 }
								 }
							 }];
}

- (void) updatePrices {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePrices) object:nil];
	__block EVECentralMarketStat* marketStat = nil;
	__block NSError* error = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 marketStat = [EVECentralMarketStat marketStatWithTypeIDs:@[@(NCPlexTypeID), @(NCTritaniumTypeID), @(NCPyeriteTypeID), @(NCMexallonTypeID), @(NCIsogenTypeID), @(NCNocxiumTypeID), @(NCZydrineTypeID), @(NCMegacyteTypeID), @(NCMorphiteTypeID)]
																							regionIDs:@[@(NCTheForgeRegionID)]
																								hours:0
																								 minQ:0
																						  cachePolicy:NSURLRequestUseProtocolCachePolicy
																								error:&error
																					  progressHandler:nil];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 if (marketStat) {
										 self.marketStat = marketStat;
										 [self performSelector:@selector(updatePrices) withObject:nil afterDelay:[self.marketStat.cacheExpireDate timeIntervalSinceNow]];
										 [self updateMarqueeLabel];
									 }
									 else {
										 [self performSelector:@selector(updatePrices) withObject:nil afterDelay:30.];
									 }
								 }
							 }];
}

- (void) updateMarqueeLabel {
	if (!self.marketStat) {
		self.marqueeLabel.text = nil;
		return;
	}
	
	NSMutableDictionary* types = [NSMutableDictionary new];
	for (EVECentralMarketStatType* type in self.marketStat.types) {
		types[@(type.typeID)] = type;
	}
	NSMutableArray* components = [NSMutableArray new];
	EVECentralMarketStatType* plex = types[@(NCPlexTypeID)];
	EVECentralMarketStatType* trit = types[@(NCTritaniumTypeID)];
	EVECentralMarketStatType* pye = types[@(NCPyeriteTypeID)];
	EVECentralMarketStatType* mex = types[@(NCMexallonTypeID)];
	EVECentralMarketStatType* iso = types[@(NCIsogenTypeID)];
	EVECentralMarketStatType* nocx = types[@(NCNocxiumTypeID)];
	EVECentralMarketStatType* zyd = types[@(NCZydrineTypeID)];
	EVECentralMarketStatType* mega = types[@(NCMegacyteTypeID)];
	EVECentralMarketStatType* morph = types[@(NCMorphiteTypeID)];
	
	NCMarketPricesMonitor settings = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsMarketPricesMonitorKey];
	
	if (plex) {
		if ((settings & NCMarketPricesMonitorExchangeRate) == NCMarketPricesMonitorExchangeRate)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"ISK 1B: $%.2f", nil), (NCPlexRate / plex.sell.percentile)]];
		if ((settings & NCMarketPricesMonitorPlex) == NCMarketPricesMonitorPlex)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"PLEX: %@", nil), [NSString shortStringWithFloat:plex.sell.percentile unit:@"ISK"]]];
	}
	if ((settings & NCMarketPricesMonitorMinerals) == NCMarketPricesMonitorMinerals) {
		if (trit)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Trit: %@", nil), [NSString shortStringWithFloat:trit.sell.percentile unit:@"ISK"]]];
		if (pye)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Pye: %@", nil), [NSString shortStringWithFloat:pye.sell.percentile unit:@"ISK"]]];
		if (mex)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Mex: %@", nil), [NSString shortStringWithFloat:mex.sell.percentile unit:@"ISK"]]];
		if (iso)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Iso: %@", nil), [NSString shortStringWithFloat:iso.sell.percentile unit:@"ISK"]]];
		if (nocx)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Nocx: %@", nil), [NSString shortStringWithFloat:nocx.sell.percentile unit:@"ISK"]]];
		if (zyd)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Zyd: %@", nil), [NSString shortStringWithFloat:zyd.sell.percentile unit:@"ISK"]]];
		if (mega)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Mega: %@", nil), [NSString shortStringWithFloat:mega.sell.percentile unit:@"ISK"]]];
		if (morph)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Morph: %@", nil), [NSString shortStringWithFloat:morph.sell.percentile unit:@"ISK"]]];
	}
	self.marqueeLabel.text = [components componentsJoinedByString:@"  "];
}

- (void) marketPricesMonitorDidChange:(NSNotification*) notification {
	[self updateMarqueeLabel];
}

@end
