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
#import "NCStorage.h"
#import "NCSetting.h"
#import "NSString+HTML.h"

//#define NCNotificationsManagerUpdateTime (60 * 30)
#define NCNotificationsManagerUpdateTime (60 * 10)

@interface NCEvent : NSObject<NSCoding>
@property (nonatomic, strong) EVEUpcomingCalendarEventsItem* event;
@property (nonatomic, strong) NSMutableArray* characterIDs;
@property (nonatomic, strong) NSString* eventIdentifier;
@property (nonatomic, strong) NSDate* localDate;
@end

@implementation NCEvent

- (id) init {
	if (self = [super init]) {
		self.characterIDs = [NSMutableArray new];
	}
	return self;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.event = [aDecoder decodeObjectForKey:@"event"];
		self.characterIDs = [[aDecoder decodeObjectForKey:@"characterIDs"] mutableCopy];
		self.eventIdentifier = [aDecoder decodeObjectForKey:@"eventIdentifier"];
		self.localDate = [aDecoder decodeObjectForKey:@"localDate"];
		if (!self.characterIDs)
			self.characterIDs = [NSMutableArray new];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.event forKey:@"event"];
	[aCoder encodeObject:self.characterIDs forKey:@"characterIDs"];
	[aCoder encodeObject:self.eventIdentifier forKey:@"eventIdentifier"];
	[aCoder encodeObject:self.localDate forKey:@"localDate"];
}

@end

@interface NCNotificationsManager()
@property (nonatomic, strong) NSDate* lastUpdate;
@property (nonatomic, strong) NSDate* lastEventsUpdate;
@property (nonatomic, strong) NCTaskManager* taskManager;
@property (nonatomic, assign, getter = isNotificationsUpdating) BOOL notificationsUpdating;
@property (nonatomic, assign, getter = isEventsUpdating) BOOL eventsUpdating;
- (void) skillQueueNotificationTimeDidChange:(NSNotification*) notification;
- (void) updateEventsIfNeeded;
- (void) updateEventsWithEventStore:(EKEventStore*) eventStore completionHandler:(void(^)(BOOL completed)) completionHandler;
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
		self.lastEventsUpdate = [defaults valueForKey:NCSettingsNotificationsLastEventsUpdateTimeKey];
		
		//self.lastUpdate = nil;
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
	self.lastEventsUpdate = nil;
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:NCSettingsNotificationsLastUpdateTimeKey];
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:NCSettingsNotificationsLastEventsUpdateTimeKey];
}

- (void) updateNotificationsIfNeededWithCompletionHandler:(void(^)(BOOL completed)) completionHandler {
	[self updateEventsIfNeeded];
	
	NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
	if (!accountsManager) {
		if (completionHandler)
			completionHandler(NO);
		return;
	}
	
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

- (void) updateEventsIfNeeded {
	if (!self.eventsUpdating && (!self.lastEventsUpdate || [self.lastEventsUpdate timeIntervalSinceNow] < -NCNotificationsManagerUpdateTime)) {
		NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
		BOOL shouldContinue = NO;
		for (NCAccount* account in accountsManager.accounts)
			if (account.accountType == NCAccountTypeCharacter) {
				shouldContinue = YES;
				break;
			}
		
		if (!shouldContinue)
			return;

		self.eventsUpdating = YES;
		EKAuthorizationStatus ekAuthorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
		EKEventStore* eventStore;
		
		if (ekAuthorizationStatus == EKAuthorizationStatusNotDetermined) {
			eventStore = [EKEventStore new];
			if (eventStore) {
				[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
					if (granted)
						[self updateEventsWithEventStore:eventStore completionHandler:^(BOOL completed) {
							if (completed) {
								self.lastEventsUpdate = [NSDate date];
								[[NSUserDefaults standardUserDefaults] setValue:self.lastEventsUpdate forKey:NCSettingsNotificationsLastEventsUpdateTimeKey];
							}
							self.eventsUpdating = NO;
						}];
					else
						self.eventsUpdating = NO;
				}];
			}
			else
				self.eventsUpdating = NO;
		}
		else if (ekAuthorizationStatus == EKAuthorizationStatusAuthorized) {
			[self updateEventsWithEventStore:[EKEventStore new] completionHandler:^(BOOL completed) {
				self.eventsUpdating = NO;
			}];
		}
		else
			self.eventsUpdating = NO;
	}
}

- (void) updateEventsWithEventStore:(EKEventStore*) eventStore completionHandler:(void(^)(BOOL completed)) completionHandler {
	if (eventStore) {
		NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
		if (accountsManager) {
			NCSetting* setting = [[NCStorage sharedStorage] settingWithKey:@"NCNotificationsManagerEvents"];
			NSMutableDictionary* events = [setting.value mutableCopy];
			if (!events)
				events = [NSMutableDictionary new];
			
			NSString* calendarIdentifier = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCalendarIdentifierKey];
			EKCalendar* calendar = calendarIdentifier ? [eventStore calendarWithIdentifier:calendarIdentifier] : nil;
			
			if (!calendar) {
				for (calendar in [eventStore calendarsForEntityType:EKEntityTypeEvent]) {
					if ([calendar.title isEqualToString:@"Neocom"] && calendar.allowsContentModifications)
						break;
				}
			}
			
			if (!calendar) {
				calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
				calendar.title = @"Neocom";
				calendar.source = [[[eventStore sources] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"sourceType == %ld", (long) EKSourceTypeSubscribed]] lastObject];
				calendar.CGColor = [[UIColor darkGrayColor] CGColor];
				
				NSError* error;
				[eventStore saveCalendar:calendar commit:YES error:&error];
				if (calendar.calendarIdentifier)
					[[NSUserDefaults standardUserDefaults] setValue:calendar.calendarIdentifier forKey:NCSettingsCalendarIdentifierKey];
			}
			
			NSMutableSet* characterIDs = [NSMutableSet new];
			[events enumerateKeysAndObjectsUsingBlock:^(id key, NCEvent* event, BOOL *stop) {
				[characterIDs addObjectsFromArray:event.characterIDs];
			}];
			
			[[self taskManager] addTaskWithIndentifier:nil
												 title:nil
												 block:^(NCTask *task) {
													 for (NCAccount* account in accountsManager.accounts) {
														 if (account.accountType != NCAccountTypeCharacter)
															 continue;
														 EVEUpcomingCalendarEvents* calendarEvents = [EVEUpcomingCalendarEvents upcomingCalendarEventsWithKeyID:account.apiKey.keyID
																																						  vCode:account.apiKey.vCode
																																					cachePolicy:NSURLRequestUseProtocolCachePolicy
																																					characterID:account.characterID
																																						  error:nil
																																				progressHandler:^(CGFloat progress, BOOL *stop) {
																																					task.progress = progress;
																																					if ([task isCancelled])
																																						*stop = YES;
																																				}];
														 [characterIDs removeObject:@(account.characterID)];
														 if (calendarEvents) {
															 NSArray* filteredEvents = [events.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"characterIDs CONTAINS %d", account.characterID]];
															 for (NCEvent* event in filteredEvents)
																 [event.characterIDs removeObject:@(account.characterID)];
															 
															 for (EVEUpcomingCalendarEventsItem* eventItem in calendarEvents.upcomingCalendarEvents) {
																 NCEvent* event = events[@(eventItem.eventID)];
																 if (!event) {
																	 events[@(eventItem.eventID)] = event = [NCEvent new];
																	 event.event = eventItem;
																	 event.localDate = [calendarEvents localTimeWithServerTime:eventItem.eventDate];
																 }
																 [event.characterIDs addObject:@(account.characterID)];
															 }
														 }
													 }

												 }
									 completionHandler:^(NCTask *task) {
										 NSMutableArray* updates = [NSMutableArray new];
										 NSMutableArray* removes = [NSMutableArray new];
										 [events enumerateKeysAndObjectsUsingBlock:^(id key, NCEvent* event, BOOL *stop) {
											 if (event.characterIDs.count == 0 && event.eventIdentifier) {
												 EKEvent* ekEvent = [eventStore eventWithIdentifier:event.eventIdentifier];
												 [eventStore removeEvent:ekEvent span:EKSpanThisEvent commit:NO error:nil];
												 [removes addObject:key];
											 }
											 else if (event.characterIDs.count > 0) {
												 EKEvent* ekEvent;
												 if (event.eventIdentifier)
													 ekEvent = [eventStore eventWithIdentifier:event.eventIdentifier];
												 
												 if (!ekEvent)
													 ekEvent = [EKEvent eventWithEventStore:eventStore];
												 ekEvent.title = [NSString stringWithFormat:@"%@: %@", event.event.ownerName, event.event.eventTitle];
												 ekEvent.notes = [[event.event.eventText stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
												 ekEvent.startDate = event.localDate;
												 ekEvent.endDate = [event.localDate dateByAddingTimeInterval:event.event.duration > 0 ? event.event.duration * 60 : 3600];
												 ekEvent.calendar = calendar;
												 [eventStore saveEvent:ekEvent span:EKSpanThisEvent commit:NO error:nil];
												 [updates addObject:@{@"ekEvent": ekEvent, @"event": event}];
											 }
										 }];
										 
										 if (removes.count > 0)
											 [events removeObjectsForKeys:removes];
										 
										 [eventStore commit:nil];
										 for (NSDictionary* item in updates) {
											 EKEvent* ekEvent = item[@"ekEvent"];
											 NCEvent* event = item[@"event"];
											 event.eventIdentifier = ekEvent.eventIdentifier;
										 }
										 NSArray* allEvents = [events allValues];
										 [eventStore enumerateEventsMatchingPredicate:[eventStore predicateForEventsWithStartDate:[NSDate date] endDate:[NSDate distantFuture]
																														calendars:@[calendar]]
																		   usingBlock:^(EKEvent *event, BOOL *stop) {
											 NSArray* filtered = [allEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"eventIdentifier = %@", event.eventIdentifier]];
											 if (filtered.count == 0)
												 [eventStore removeEvent:event span:EKSpanThisEvent commit:NO error:nil];
										 }];
										 
										 [eventStore commit:nil];
										 
										 setting.value = events;
										 NSManagedObjectContext* context = [[NCStorage sharedStorage] managedObjectContext];
										 [context performBlock:^{
											 [context save:nil];
										 }];
										 if (completionHandler)
											 completionHandler(YES);
									 }];
		}
		else if (completionHandler)
			completionHandler(NO);
	}
	else if (completionHandler)
		completionHandler(NO);
}

@end
