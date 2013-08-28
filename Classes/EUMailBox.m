//
//  EUMailBox.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EUMailBox.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "Globals.h"

@interface EUMailBox()
@property (nonatomic, readwrite) NSInteger numberOfUnreadMessages;
@property (nonatomic, readwrite, strong) NSArray* inbox;
@property (nonatomic, readwrite, strong) NSArray* sent;
@property (nonatomic, readwrite, strong) NSArray* notifications;
@property (nonatomic, weak, readwrite) EVEAccount* account;
@property (nonatomic, readwrite, strong) NSError* error;

+ (NSString*) mailBoxDirectory;
- (NSString*) messagesFilePath;
- (NSString*) notificationsFilePath;
- (void) reload;

@end

@implementation EUMailBox

+ (id) mailBoxWithAccount:(EVEAccount*) account {
	return [[EUMailBox alloc] initWithAccount:account];
}

- (id) initWithAccount:(EVEAccount*) account {
	if (self = [super init]) {
		if (!account.charAPIKey)
			return nil;
		self.account = account;
	}
	return self;
}

- (NSArray*) inbox {
	if (!_inbox) {
		[self reload];
	}
	return _inbox;
}

- (NSArray*) sent {
	if (!_sent) {
		[self reload];
	}
	return _sent;
}

- (NSArray*) notifications {
	if (!_notifications) {
		[self reload];
	}
	return _notifications;
}

- (NSInteger) numberOfUnreadMessages {
	NSInteger unreaded = 0;
	for (EUMailMessage* message in self.inbox)
		if (!message.read)
			unreaded++;
	return unreaded;
}

- (void) save {
	[[NSFileManager defaultManager] createDirectoryAtPath:[EUMailBox mailBoxDirectory] withIntermediateDirectories:NO attributes:nil error:nil];
	NSMutableArray* readMessages = [[NSMutableArray alloc] init];
	for (EUMailMessage* message in self.inbox)
		if (message.read)
			[readMessages addObject:[NSNumber numberWithInteger:message.header.messageID]];
	[readMessages writeToURL:[NSURL fileURLWithPath:[self messagesFilePath]] atomically:YES];
	
	NSMutableArray* readNotifications = [[NSMutableArray alloc] init];
	for (EUNotification* notification in self.notifications)
		[readNotifications addObject:[NSNumber numberWithInteger:notification.header.notificationID]];
	[readNotifications writeToURL:[NSURL fileURLWithPath:[self notificationsFilePath]] atomically:YES];
}

#pragma mark - Private

+ (NSString*) mailBoxDirectory {
	return [[Globals cachesDirectory] stringByAppendingPathComponent:@"MailBox"];
}

- (NSString*) messagesFilePath {
	return [[EUMailBox mailBoxDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"m%d.plist", self.account.character.characterID]];
}

- (NSString*) notificationsFilePath {
	return [[EUMailBox mailBoxDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"n%d.plist", self.account.character.characterID]];
}

- (void) reload {
	self.inbox = nil;
	self.sent = nil;
	self.notifications = nil;
	
	self.error = nil;
	NSError *error = nil;
	
	EVEMailMessages* mailMessages = [EVEMailMessages mailMessagesWithKeyID:self.account.charAPIKey.keyID vCode:self.account.charAPIKey.vCode characterID:self.account.character.characterID error:&error progressHandler:nil];
	EVENotifications* eveNotifications = [EVENotifications notificationsWithKeyID:self.account.charAPIKey.keyID vCode:self.account.charAPIKey.vCode characterID:self.account.character.characterID error:&error progressHandler:nil];
	if (error) {
		self.error = error;
	}
	else {
		EVEMailingLists* mailingLists = [EVEMailingLists mailingListsWithKeyID:self.account.charAPIKey.keyID vCode:self.account.charAPIKey.vCode characterID:self.account.character.characterID error:nil progressHandler:nil];
		NSArray* readMessages = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[self messagesFilePath]]];
		NSArray* readNotifications = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[self notificationsFilePath]]];
		
		NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit fromDate:[NSDate date]];
		components.hour = 0;
		NSDate* today = [calendar dateFromComponents:components];
		NSDate* yesterday = [today dateByAddingTimeInterval:-60 * 60 * 24];
		
		self.inbox = [[NSMutableArray alloc] init];
		self.sent = [[NSMutableArray alloc] init];
		self.notifications = [[NSMutableArray alloc] initWithCapacity:eveNotifications.notifications.count];
		NSMutableSet* ids = [NSMutableSet set];
		
		NSDateFormatter* dateFormatterTime = [[NSDateFormatter alloc] init];
		NSDateFormatter* dateFormatterFull = [[NSDateFormatter alloc] init];
		[dateFormatterTime setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatterFull setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatterTime setDateFormat:@"HH:mm"];
		[dateFormatterFull setDateFormat:@"yyyy.MM.dd HH:mm"];
		
		NSMutableDictionary*characterNames = [NSMutableDictionary dictionary];
		for (EVEMailMessagesItem* item in mailMessages.mailMessages) {
			if (item.toCorpOrAllianceID)
				[ids addObject:[NSString stringWithFormat:@"%d", item.toCorpOrAllianceID]];
			if (item.senderID) {
				NSString* key = [NSString stringWithFormat:@"%d", item.senderID];
				EVEMailingListsItem* list = [mailingLists.mailingListsMap valueForKey:key];
				if (list.displayName)
					[characterNames setValue:list.displayName forKey:[NSString stringWithFormat:@"%d", item.senderID]];
				else
					[ids addObject:[NSString stringWithFormat:@"%d", item.senderID]];
			}
			for (NSString* charID in item.toCharacterIDs)
				[ids addObject:charID];
			EUMailMessage* message = [EUMailMessage mailMessageWithMailBox:self];
			message.header = item;
			if (item.senderID == self.account.character.characterID) {
				[(NSMutableArray*) self.sent addObject:message];
				message.read = YES;
			}
			else {
				[(NSMutableArray*) self.inbox addObject:message];
				message.read = !readMessages || [readMessages containsObject:[NSNumber numberWithInteger:message.header.messageID]];
			}
			
			if ([item.sentDate laterDate:today] == item.sentDate)
				message.date = [NSString stringWithFormat:NSLocalizedString(@"Today at %@", nil), [dateFormatterTime stringFromDate:item.sentDate]];
			else if ([item.sentDate laterDate:yesterday] == item.sentDate)
				message.date = [NSString stringWithFormat:NSLocalizedString(@"Yesterday at %@", nil), [dateFormatterTime stringFromDate:item.sentDate]];
			else
				message.date = [dateFormatterFull stringFromDate:item.sentDate];
		}
		
		for (EVENotificationsItem* item in eveNotifications.notifications) {
			if (item.senderID) {
				[ids addObject:[NSString stringWithFormat:@"%d", item.senderID]];
			}
			EUNotification* notification = [EUNotification notificationWithMailBox:self];
			notification.header = item;
			[(NSMutableArray*) self.notifications addObject:notification];
		}
		
		NSArray* idsArray = [ids allObjects];
		NSRange range = NSMakeRange(0, MIN(idsArray.count, 250));
		while (range.length > 0) {
			EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:[idsArray subarrayWithRange:range] error:nil progressHandler:nil];
			if (characterName.characters.count > 0)
				[characterNames addEntriesFromDictionary:characterName.characters];
			range.location += range.length;
			range.length = idsArray.count - range.location;
			if (range.length > 250)
				range.length = 250;
		}
		
		for (EUMailMessage* message in [self.inbox arrayByAddingObjectsFromArray:self.sent]) {
			if (message.header.toCorpOrAllianceID) {
				NSString* to = [characterNames valueForKey:[NSString stringWithFormat:@"%d", message.header.toCorpOrAllianceID]];
				if (to)
					message.to = to;
				else
					message.to = NSLocalizedString(@"Unknown corporation or alliance", nil);
			}
			else if (message.header.toListID.count > 0) {
				NSMutableArray* lists = [NSMutableArray array];
				for (NSNumber* listID in message.header.toListID) {
					EVEMailingListsItem* list = [mailingLists.mailingListsMap valueForKey:[NSString stringWithFormat:@"%@", listID]];
					if (list.displayName)
						[lists addObject:list.displayName];
				}
				if (lists.count > 0)
					message.to = [lists componentsJoinedByString:@", "];
				else
					message.to = NSLocalizedString(@"Unknown mailing list", nil);
			}
			else if (message.header.toCharacterIDs.count > 0) {
				NSMutableArray* names = [[NSMutableArray alloc] init];
				for (NSString* key in message.header.toCharacterIDs) {
					NSString* name = [characterNames valueForKey:key];
					if (name)
						[names addObject:name];
				}
				message.to = [names componentsJoinedByString:@", "];
			}
			if (!message.to)
				message.to = NSLocalizedString(@"Unknown recipient", nil);
			
			NSString* from = [characterNames valueForKey:[NSString stringWithFormat:@"%d", message.header.senderID]];
			if (from)
				message.from = from;
			else
				message.from = NSLocalizedString(@"Unknown sender", nil);
		}
		[(NSMutableArray*) self.inbox sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
		[(NSMutableArray*) self.sent sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
		
		for (EUNotification* notification in self.notifications) {
			NSString* sender = [characterNames valueForKey:[NSString stringWithFormat:@"%d", notification.header.senderID]];
			if (sender)
				notification.sender = sender;
			else
				notification.sender = NSLocalizedString(@"Unknown sender", nil);
			if (!readNotifications)
				notification.read = notification.header.read;
			else
				notification.read = notification.header.read || [readNotifications containsObject:[NSNumber numberWithInteger:notification.header.notificationID]];
		}
	}
}

@end
