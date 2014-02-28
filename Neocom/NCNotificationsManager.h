//
//  NCNotificationsManager.h
//  Neocom
//
//  Created by Артем Шиманский on 28.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, NCNotificationsManagerSkillQueueNotificationTime) {
	NCNotificationsManagerSkillQueueNotificationTime1Day = 0x1 << 0,
	NCNotificationsManagerSkillQueueNotificationTime12Hours = 0x1 << 1,
	NCNotificationsManagerSkillQueueNotificationTime4Hours = 0x1 << 2,
	NCNotificationsManagerSkillQueueNotificationTime1Hour = 0x1 << 3,
	NCNotificationsManagerSkillQueueNotificationTimeAll = NCNotificationsManagerSkillQueueNotificationTime1Day | NCNotificationsManagerSkillQueueNotificationTime12Hours | NCNotificationsManagerSkillQueueNotificationTime4Hours | NCNotificationsManagerSkillQueueNotificationTime1Hour
};

@interface NCNotificationsManager : NSObject
@property (nonatomic, assign) NCNotificationsManagerSkillQueueNotificationTime skillQueueNotificationTime;

+ (id) sharedManager;

- (void) setNeedsUpdateNotifications;
- (void) updateNotificationsIfNeededWithCompletionHandler:(void(^)(BOOL newData)) completionHandler;
@end
