//
//  NCNotificationsManager.m
//  Neocom
//
//  Created by Артем Шиманский on 28.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCNotificationsManager.h"
#import "NCTaskManager.h"
#import "NCAccountsManager.h"
#import "NCTodayRow.h"

#define NCNotificationsManagerUpdateTime (60 * 30)

@interface NCNotificationsManager()
@property (nonatomic, strong) NSDate* lastUpdate;
@property (nonatomic, strong) NCTaskManager* taskManager;
@property (nonatomic, assign, getter = isNotificationsUpdating) BOOL notificationsUpdating;
- (void) skillQueueNotificationTimeDidChange:(NSNotification*) notification;
@end

@implementation NCNotificationsManager

+ (id) sharedManager {
	@synchronized(self) {
		static NCNotificationsManager* manager = nil;
		if (!manager)
			manager = [NCNotificationsManager new];
		return manager;
	}
}

- (id) init {
	if (self = [super init]) {
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		self.lastUpdate = [defaults valueForKey:NCSettingsNotificationsLastUpdateTimeKey];
		self.lastUpdate = nil;
		self.taskManager = [NCTaskManager new];
		self.skillQueueNotificationTime = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsSkillQueueNotificationTimeKey];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(skillQueueNotificationTimeDidChange:) name:NCSkillQueueNotificationTimeDidChangeNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCSkillQueueNotificationTimeDidChangeNotification object:nil];
}

- (void) setNeedsUpdateNotifications {
	self.lastUpdate = nil;
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:NCSettingsNotificationsLastUpdateTimeKey];
}

- (void) updateNotificationsIfNeededWithCompletionHandler:(void(^)(BOOL completed)) completionHandler {
	NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
	if (!accountsManager)
		return;
	
	if (!self.notificationsUpdating && (!self.lastUpdate || [self.lastUpdate timeIntervalSinceNow] < -NCNotificationsManagerUpdateTime)) {
		self.notificationsUpdating = YES;
		NSMutableArray* notifications = [NSMutableArray new];
		NSMutableSet* accounts = [NSMutableSet new];
		

		[[self taskManager] addTaskWithIndentifier:nil
											 title:nil
											 block:^(NCTask *task) {
												 NSMutableArray* todayRows = [NSMutableArray new];
												 
												 for (NCAccount* account in accountsManager.accounts) {
													 if (account.accountType != NCAccountTypeCharacter)
														 continue;
													 if (!account.uuid)
														 continue;

													 NCTodayRow* row = [NCTodayRow new];
													 row.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSizeRetina64 error:nil]]];
													 row.name = account.characterInfo.characterName;
													 row.uuid = account.uuid;
													 [todayRows addObject:row];
													 
													 if (!account.skillQueue)
														 continue;
													 
													 if  ([account.skillQueue.cacheExpireDate compare:[NSDate date]] == NSOrderedAscending) {
														 [account reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy
																				  error:nil
																		progressHandler:nil];
													 }
													 
													 NSDate *endTime = account.skillQueue.skillQueue.count > 0 ? [[account.skillQueue.skillQueue lastObject] endTime] : nil;
													 row.skillQueueEndDate = [account.skillQueue localTimeWithServerTime:endTime];

													 
													 [accounts addObject:account.uuid];
													 if (account.skillQueue.skillQueue.count == 0)
														 continue;
													 
													 if (endTime) {
														 endTime = [account.skillQueue localTimeWithServerTime:endTime];
														 NSTimeInterval dif = [endTime timeIntervalSinceNow];
														 
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime1Day) && dif > 3600 * 24) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 24 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 24];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 notification.soundName = UILocalNotificationDefaultSoundName;
															 [notifications addObject:notification];
														 }

														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime12Hours) && dif > 3600 * 12) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 12 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 12];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 notification.soundName = UILocalNotificationDefaultSoundName;
															 [notifications addObject:notification];
														 }

														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime4Hours) && dif > 3600 * 4) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 4 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 4];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 notification.soundName = UILocalNotificationDefaultSoundName;
															 [notifications addObject:notification];
														 }
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime1Hour) && dif > 3600 * 1) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 1 hour training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 1];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 notification.soundName = UILocalNotificationDefaultSoundName;
															 [notifications addObject:notification];
														 }
													 }
												 }
												 [notifications sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fireDate" ascending:YES]]];
												 NSInteger badge = 1;
												 NSMutableSet* uuids = [NSMutableSet new];
												 for (UILocalNotification* notification in notifications) {
													 NSString* uuid = notification.userInfo[NCSettingsCurrentAccountKey];
													 if (![uuids containsObject:uuid]) {
														 notification.applicationIconBadgeNumber = badge++;
														 [uuids addObject:uuid];
													 }
												 }
												 
												 NSURL* url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.shimanski.eveuniverse.today"];
												 if (url) {
													 url = [url URLByAppendingPathComponent:@"today.plist"];
													 NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
													 [coordinator coordinateWritingItemAtURL:url
																					 options:NSFileCoordinatorWritingForReplacing
																					   error:nil
																				  byAccessor:^(NSURL *newURL) {
																					  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:todayRows];
																					  [data writeToURL:newURL atomically:YES];
																				  }];
												 }
											 }
								 completionHandler:^(NCTask *task) {
									 self.notificationsUpdating = NO;
									 if (![task isCancelled]) {
										 if (accounts.count == 0)
											 return;
										 
										 UIApplication* application = [UIApplication sharedApplication];
										 for (UILocalNotification* notification in application.scheduledLocalNotifications)
											 [application cancelLocalNotification:notification];
										 
										 for (UILocalNotification* notification in notifications)
											 [application scheduleLocalNotification:notification];
										 
										 self.lastUpdate = [NSDate date];
										 [[NSUserDefaults standardUserDefaults] setValue:self.lastUpdate forKey:NCSettingsNotificationsLastUpdateTimeKey];
									 }
									 if (completionHandler)
										 completionHandler(accounts.count > 0);
								 }];
	}
	else {
		UIApplication* application = [UIApplication sharedApplication];
		NSMutableArray* notifications = [application.scheduledLocalNotifications mutableCopy];
		[notifications sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fireDate" ascending:YES]]];
		NSInteger badge = 1;
		NSMutableSet* uuids = [NSMutableSet new];
		for (UILocalNotification* notification in notifications) {
			[application cancelLocalNotification:notification];
			
			NSString* uuid = notification.userInfo[NCSettingsCurrentAccountKey];
			if (uuid && ![uuids containsObject:uuid]) {
				notification.applicationIconBadgeNumber = badge++;
				[uuids addObject:uuid];
			}
			
			[application scheduleLocalNotification:notification];
		}
		
		if (completionHandler)
			completionHandler(NO);
	}
}

#pragma mark - Private

- (void) skillQueueNotificationTimeDidChange:(NSNotification*) notification {
	[self setNeedsUpdateNotifications];
	self.skillQueueNotificationTime = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsSkillQueueNotificationTimeKey];
}

@end
