//
//  NCMainMenuViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuViewController.h"
#import "NCStorage.h"
#import "NCTableViewEmptyHedaerView.h"
#import "NCSideMenuViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"

@interface NCMainMenuViewController ()
@property (nonatomic, strong) NSMutableArray* allSections;
@property (nonatomic, strong) NSMutableArray* sections;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, strong) EVEServerStatus* serverStatus;
@property (nonatomic, readonly) NSString* skillsDetails;
@property (nonatomic, readonly) NSString* skillQueueDetails;
@property (nonatomic, readonly) NSString* mailsDetails;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
- (void) reload;
- (void) onTimer:(NSTimer*) timer;
- (void) updateServerStatus;
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
	[self.tableView registerClass:[NCTableViewEmptyHedaerView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewEmptyHedaerView"];
	self.allSections = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];
	[self reload];
	
	self.dateFormatter = [NSDateFormatter new];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	[self.dateFormatter setDateFormat:@"HH:mm:ss"];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	if (self.serverStatus) {
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
		[self onTimer:self.timer];
	}
	else
		[self updateServerStatus];
	if (self.skillQueue.cacheExpireDate) {
		NSTimeInterval delay = [self.skillQueue.cacheExpireDate timeIntervalSinceNow];
		if (delay > 0)
			[self performSelector:@selector(reload) withObject:nil afterDelay:[self.skillQueue.cacheExpireDate timeIntervalSinceNow]];
		else
			[self reload];
	}
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.timer = nil;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) dealloc {
	self.timer = nil;
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
	UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	
	cell.textLabel.text = row[@"title"];
	cell.imageView.image = [UIImage imageNamed:row[@"image"]];
	NSString* detailsKeyPath = row[@"detailsKeyPath"];
	if (detailsKeyPath)
		cell.detailTextLabel.text = [self valueForKey:detailsKeyPath];
	else
		cell.detailTextLabel.text = nil;
	return cell;
}

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else
		return [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewEmptyHedaerView"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return 0;
	else
		return 22;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	[self performSegueWithIdentifier:row[@"segueIdentifier"] sender:[tableView cellForRowAtIndexPath:indexPath]];
	
//	[self.sideMenuViewController setContentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCCharacterSheetViewController"] animated:YES];
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

- (BOOL) shouldReloadData {
	return YES;
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
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
									 [self.tableView reloadData];
									 
									 if (self.skillQueue) {
										 NSTimeInterval delay = [self.skillQueue.cacheExpireDate timeIntervalSinceNow];
										 if (delay > 0)
											 [self performSelector:@selector(reload) withObject:nil afterDelay:[self.skillQueue.cacheExpireDate timeIntervalSinceNow]];
									 }
								 }
							 }];
}

- (NSString*) skillsDetails {
	if (self.characterSheet) {
		NSInteger skillPoints = 0;
		for (EVECharacterSheetSkill* skill in self.characterSheet.skills)
			skillPoints += skill.skillpoints;
		return [NSString stringWithFormat:NSLocalizedString(@"%@ skillpoints (%d skills)", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:skillPoints], (int32_t) self.characterSheet.skills.count];
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

@end
