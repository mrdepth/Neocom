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

#define NCNotificationsManagerUpdateTime (60 * 30)

@interface NCNotificationsManager()
@property (nonatomic, strong) NSDate* lastUpdate;
@property (nonatomic, strong) NCTaskManager* taskManager;
@property (nonatomic, assign, getter = isNotificationsUpdating) BOOL notificationsUpdating;

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
		self.skillQueueNotificationTime = NCNotificationsManagerSkillQueueNotificationTimeAll;
	}
	return self;
}

- (void) setNeedsUpdateNotifications {
	self.lastUpdate = nil;
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:NCSettingsNotificationsLastUpdateTimeKey];
}

- (void) updateNotificationsIfNeededWithCompletionHandler:(void(^)(BOOL completed)) completionHandler {
	if (!self.notificationsUpdating && (!self.lastUpdate || [self.lastUpdate timeIntervalSinceNow] < -NCNotificationsManagerUpdateTime)) {
		self.notificationsUpdating = YES;
		NSMutableArray* notifications = [NSMutableArray new];
		NSMutableSet* accounts = [NSMutableSet new];
		[[self taskManager] addTaskWithIndentifier:nil
											 title:nil
											 block:^(NCTask *task) {
												 for (NCAccount* account in [[NCAccountsManager defaultManager] accounts]) {
													 if (account.accountType != NCAccountTypeCharacter || !account.skillQueue)
														 continue;
													 [accounts addObject:account.uuid];
													 if (account.skillQueue.skillQueue.count == 0)
														 continue;
													 
													 NSDate *endTime = [[account.skillQueue.skillQueue lastObject] endTime];
													 if (endTime) {
														 endTime = [account.skillQueue localTimeWithServerTime:endTime];
														 NSTimeInterval dif = [endTime timeIntervalSinceNow];
														 
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime1Day) && dif > 3600 * 24) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 24 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 24];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 [notifications addObject:notification];
														 }
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime12Hours) && dif > 3600 * 12) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 12 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 12];

															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 [notifications addObject:notification];
														 }
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime4Hours) && dif > 3600 * 4) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 4 hours training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 4];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 [notifications addObject:notification];
														 }
														 if ((self.skillQueueNotificationTime & NCNotificationsManagerSkillQueueNotificationTime4Hours) && dif > 3600 * 1) {
															 UILocalNotification *notification = [[UILocalNotification alloc] init];
															 notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 1 hour training left.", nil), account.characterInfo.characterName];
															 notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 1];
															 notification.userInfo = @{NCSettingsCurrentAccountKey: account.uuid};
															 [notifications addObject:notification];
														 }
													 }
												 }
											 }
								 completionHandler:^(NCTask *task) {
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
									 self.notificationsUpdating = NO;
								 }];
	}
	else if (completionHandler)
		completionHandler(NO);
}

#pragma mark - Private

@end
