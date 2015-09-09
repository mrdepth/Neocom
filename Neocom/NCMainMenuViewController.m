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
#import "NCDefaultTableViewCell.h"
#import "NCSplitViewController.h"
#import "NCPriceManager.h"

#define NCMarketPricesMonitorDidChangeNotification @"NCMarketPricesMonitorDidChangeNotification"

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
@property (nonatomic, readonly) NSString* skillsDetails;
@property (nonatomic, readonly) NSString* skillQueueDetails;
@property (nonatomic, readonly) NSString* mailsDetails;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, assign) BOOL reloading;
@property (nonatomic, strong) NSDictionary* prices;
@property (nonatomic, strong) NCPriceManager* priceManager;
- (void) reload;
- (void) onTimer:(NSTimer*) timer;
- (void) updateServerStatus;
- (void) updatePrices;
- (void) updateMarqueeLabel;
- (void) marketPricesMonitorDidChange:(NSNotification*) notification;
- (void) priceManagerDidUpdate:(NSNotification*) notification;
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
	self.priceManager = [NCPriceManager new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(marketPricesMonitorDidChange:) name:NCMarketPricesMonitorDidChangeNotification object:nil];
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
	[self updateServerStatus];
	
	[self updatePrices];
	[self reload];
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
//	NCSplitViewController* splitViewController = (NCSplitViewController*) self.splitViewController;
//	[splitViewController.masterPopover dismissPopoverAnimated:YES];
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

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else
		return [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewEmptyHeaderView"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	NSString* identifier = row[@"segueIdentifier"];
	if (identifier)
		[self performSegueWithIdentifier:row[@"segueIdentifier"] sender:[tableView cellForRowAtIndexPath:indexPath]];
	else {
		NSString* urlString = row[@"url"];
		if (urlString)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	}
}

#pragma mark - NCTableViewController

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	if ([self isViewLoaded] && self.view.window)
		[self reload];
}

- (void) didChangeStorage:(NSNotification *)notification {
	[super didChangeStorage:notification];
	if ([self isViewLoaded] && self.view.window)
		[self reload];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell* tableViewCell = (NCDefaultTableViewCell*) cell;
	tableViewCell.subtitleLabel.numberOfLines = 2;
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	
	tableViewCell.titleLabel.text = row[@"title"];
	tableViewCell.iconView.image = [UIImage imageNamed:row[@"image"]];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	if (detailsKeyPath) {
		tableViewCell.subtitleLabel.text = [self valueForKey:detailsKeyPath];
		tableViewCell.subtitleLabel.numberOfLines = [tableViewCell.subtitleLabel.text componentsSeparatedByString:@"\n"].count;
	}
	else
		tableViewCell.subtitleLabel.text = nil;
	
	if (!tableViewCell.accessoryView) {
		tableViewCell.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 44)];
		tableViewCell.accessoryView.hidden = NO;
	}

}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

#pragma mark - Private

- (void) reload {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reload) object:nil];
	if (self.reloading)
		return;
	
	self.reloading = YES;
	NCAccount* account = [NCAccount currentAccount];
	
	void (^reload)(NSInteger, NSString*) = ^(NSInteger apiKeyAccessMask, NSString* accessMaskKey) {
		self.sections = [NSMutableArray new];
		for (NSArray* rows in self.allSections) {
			NSMutableArray* section = [NSMutableArray new];
			for (NSDictionary* row in rows) {
				NSInteger accessMask = [row[accessMaskKey] integerValue];
				if ((accessMask & apiKeyAccessMask) == accessMask) {
					[section addObject:row];
				}
			}
			if (section.count > 0)
				[self.sections addObject:section];
		}
		
		[self.tableView reloadData];
		self.reloading = NO;
	};
	
	if (account) {
		[account.managedObjectContext performBlock:^{
			NSInteger apiKeyAccessMask = account.apiKey.apiKeyInfo.key.accessMask;
			NSString* accessMaskKey = account.accountType == NCAccountTypeCorporate ? @"corpAccessMask" : @"charAccessMask" ;
			dispatch_async(dispatch_get_main_queue(), ^{
				reload(apiKeyAccessMask, accessMaskKey);
				
				[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					[account loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error) {
						self.characterSheet = characterSheet;
						self.skillQueue = skillQueue;
						[self.tableView reloadData];
						
						NSTimeInterval delay = 0;
						if (self.skillQueue)
							delay = [[self.skillQueue.eveapi localTimeWithServerTime:self.skillQueue.eveapi.cachedUntil] timeIntervalSinceNow];
						else if (self.characterSheet)
							delay = [[self.characterSheet.eveapi localTimeWithServerTime:self.characterSheet.eveapi.cachedUntil] timeIntervalSinceNow];
						if (delay > 0)
							[self performSelector:@selector(reload) withObject:nil afterDelay:delay];
					}];
				}];
			});
		}];
	}
	else {
		reload(0, @"charAccessMask");
	}
}

- (NSString*) skillsDetails {
	if (self.characterSheet) {
		NSInteger skillPoints = 0;
		for (EVECharacterSheetSkill* skill in self.characterSheet.skills)
			skillPoints += skill.skillpoints;

		return [NSString stringWithFormat:NSLocalizedString(@"%@ skillpoints (%d skills)\n%@", nil),
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
		self.serverTimeLabel.text = [self.dateFormatter stringFromDate:[self.serverStatus.eveapi serverTimeWithLocalTime:[NSDate date]]];
	}
}

- (void) setTimer:(NSTimer *)timer {
	[_timer invalidate];
	_timer = timer;
}

- (void) updateServerStatus {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateServerStatus) object:nil];

	void (^update)(EVEAPIKey* apiKey) = ^(EVEAPIKey* apiKey) {
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:apiKey cachePolicy:NSURLRequestUseProtocolCachePolicy];
		[api serverStatusWithCompletionBlock:^(EVEServerStatus *result, NSError *error) {
			self.serverStatus = result;
			if (result) {
				if (result.serverOpen)
					self.serverStatusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ players online", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:result.onlinePlayers]];
				else
					self.serverStatusLabel.text = NSLocalizedString(@"Server offline", nil);
				
				[self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:[[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil] timeIntervalSinceNow]];
				[self onTimer:self.timer];
			}
			else {
				self.serverStatusLabel.text = [error localizedDescription];
				[self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:60];
			}
			
		} progressBlock:nil];
	};
	
	if (!self.serverStatus || !self.serverStatus.eveapi.cachedUntil || [[self.serverStatus.eveapi localTimeWithServerTime:self.serverStatus.eveapi.cachedUntil] compare:[NSDate date]] == NSOrderedAscending) {
		NCAccount* account = [NCAccount currentAccount];
		if (account)
			[account.managedObjectContext performBlock:^{
				EVEAPIKey* apiKey = account.eveAPIKey;
				dispatch_async(dispatch_get_main_queue(), ^{
					update(apiKey);
				});
			}];
		else
			update(nil);
	}
	else if (self.serverStatus) {
		[self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:[[self.serverStatus.eveapi localTimeWithServerTime:self.serverStatus.eveapi.cachedUntil] timeIntervalSinceNow]];
	}
	
	
/*	__block EVEServerStatus* serverStatus = nil;
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
										 [self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:MAX([serverStatus.cacheExpireDate timeIntervalSinceNow], 60)];
									 }
									 else {
										 if (error)
											 self.serverStatusLabel.text = [error localizedDescription];
										 else
											 self.serverStatusLabel.text = NSLocalizedString(@"Server offline", nil);
										 [self performSelector:@selector(updateServerStatus) withObject:nil afterDelay:60.];
									 }
								 }
							 }];*/
}

- (void) updatePrices {
	[self.priceManager requestPricesWithTypes:@[@(NCPlexTypeID), @(NCTritaniumTypeID), @(NCPyeriteTypeID), @(NCMexallonTypeID), @(NCIsogenTypeID), @(NCNocxiumTypeID), @(NCZydrineTypeID), @(NCMegacyteTypeID), @(NCMorphiteTypeID)]
							  completionBlock:^(NSDictionary *prices) {
								  self.prices = prices;
								  [self updateMarqueeLabel];
							  }];
}

- (void) updateMarqueeLabel {
	if (!self.prices) {
		self.marqueeLabel.text = nil;
		return;
	}
	
	NSMutableArray* components = [NSMutableArray new];
	NSNumber* plex = self.prices[@(NCPlexTypeID)];
	NSNumber* trit = self.prices[@(NCTritaniumTypeID)];
	NSNumber* pye = self.prices[@(NCPyeriteTypeID)];
	NSNumber* mex = self.prices[@(NCMexallonTypeID)];
	NSNumber* iso = self.prices[@(NCIsogenTypeID)];
	NSNumber* nocx = self.prices[@(NCNocxiumTypeID)];
	NSNumber* zyd = self.prices[@(NCZydrineTypeID)];
	NSNumber* mega = self.prices[@(NCMegacyteTypeID)];
	NSNumber* morph = self.prices[@(NCMorphiteTypeID)];
	
	NCMarketPricesMonitor settings = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsMarketPricesMonitorKey];
	
	if (plex) {
		if ((settings & NCMarketPricesMonitorExchangeRate) == NCMarketPricesMonitorExchangeRate)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"ISK 1B: $%.2f", nil), (NCPlexRate / [plex floatValue])]];
		if ((settings & NCMarketPricesMonitorPlex) == NCMarketPricesMonitorPlex)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"PLEX: %@", nil), [NSString shortStringWithFloat:[plex floatValue] unit:@"ISK"]]];
	}
	if ((settings & NCMarketPricesMonitorMinerals) == NCMarketPricesMonitorMinerals) {
		if (trit)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Trit: %@", nil), [NSString shortStringWithFloat:[trit floatValue] unit:@"ISK"]]];
		if (pye)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Pye: %@", nil), [NSString shortStringWithFloat:[pye floatValue] unit:@"ISK"]]];
		if (mex)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Mex: %@", nil), [NSString shortStringWithFloat:[mex floatValue] unit:@"ISK"]]];
		if (iso)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Iso: %@", nil), [NSString shortStringWithFloat:[iso floatValue] unit:@"ISK"]]];
		if (nocx)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Nocx: %@", nil), [NSString shortStringWithFloat:[nocx floatValue] unit:@"ISK"]]];
		if (zyd)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Zyd: %@", nil), [NSString shortStringWithFloat:[zyd floatValue] unit:@"ISK"]]];
		if (mega)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Mega: %@", nil), [NSString shortStringWithFloat:[mega floatValue] unit:@"ISK"]]];
		if (morph)
			[components addObject:[NSString stringWithFormat:NSLocalizedString(@"Morph: %@", nil), [NSString shortStringWithFloat:[morph floatValue] unit:@"ISK"]]];
	}
	self.marqueeLabel.text = [components componentsJoinedByString:@"  "];
}

- (void) marketPricesMonitorDidChange:(NSNotification*) notification {
	[self updateMarqueeLabel];
}

- (void) priceManagerDidUpdate:(NSNotification*) notification {
	[self updatePrices];
}

@end
