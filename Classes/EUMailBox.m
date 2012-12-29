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

@interface EUMailBox(Private)

+ (NSString*) mailBoxDirectory;
- (NSString*) messagesFilePath;
- (NSString*) notificationsFilePath;
- (void) reload;

@end

@implementation EUMailBox
@synthesize inbox;
@synthesize sent;
@synthesize notifications;
@synthesize keyID;
@synthesize vCode;
@synthesize characterID;
@synthesize error;

+ (id) mailBoxWithAccount:(EVEAccount*) account {
	return [[[EUMailBox alloc] initWithAccount:account] autorelease];
}

- (id) initWithAccount:(EVEAccount*) account {
	if (self = [super init]) {
		if (!account.charKeyID || !account.charVCode) {
			[self release];
			return nil;
		}
		characterID = account.characterID;
		vCode = [account.charVCode retain];
		keyID = account.charKeyID;
	}
	return self;
}

- (void) dealloc {
	[inbox release];
	[sent release];
	[notifications release];
	[vCode release];
	[error release];
	[super dealloc];
}

- (NSArray*) inbox {
	if (!inbox) {
		[self reload];
	}
	return inbox;
}

- (NSArray*) sent {
	if (!sent) {
		[self reload];
	}
	return sent;
}

- (NSArray*) notifications {
	if (!notifications) {
		[self reload];
	}
	return notifications;
}

- (NSInteger) numberOfUnreadMessages {
	NSInteger unreaded = 0;
	for (EUMailMessage* message in inbox)
		if (!message.read)
			unreaded++;
	return unreaded;
}

- (void) save {
	[[NSFileManager defaultManager] createDirectoryAtPath:[EUMailBox mailBoxDirectory] withIntermediateDirectories:NO attributes:nil error:nil];
	NSMutableArray* readMessages = [[NSMutableArray alloc] init];
	for (EUMailMessage* message in inbox)
		if (message.read)
			[readMessages addObject:[NSNumber numberWithInteger:message.header.messageID]];
	[readMessages writeToURL:[NSURL fileURLWithPath:[self messagesFilePath]] atomically:YES];
	[readMessages release];
	
	NSMutableArray* readNotifications = [[NSMutableArray alloc] init];
	for (EUNotification* notification in notifications)
		[readNotifications addObject:[NSNumber numberWithInteger:notification.header.notificationID]];
	[readNotifications writeToURL:[NSURL fileURLWithPath:[self notificationsFilePath]] atomically:YES];
	[readNotifications release];
}

@end

@implementation EUMailBox(Private)

+ (NSString*) mailBoxDirectory {
	return [[Globals cachesDirectory] stringByAppendingPathComponent:@"MailBox"];
}

- (NSString*) messagesFilePath {
	return [[EUMailBox mailBoxDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"m%d.plist", characterID]];
}

- (NSString*) notificationsFilePath {
	return [[EUMailBox mailBoxDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"n%d.plist", characterID]];
}

- (void) reload {
	[inbox release];
	[sent release];
	[notifications release];
	inbox = nil;
	sent = nil;
	notifications = nil;
	
	[error release];
	error = nil;
	EVEMailMessages* mailMessages = [EVEMailMessages mailMessagesWithKeyID:keyID vCode:vCode characterID:characterID error:&error];
	EVENotifications* eveNotifications = [EVENotifications notificationsWithKeyID:keyID vCode:vCode characterID:characterID error:&error];
	if (error) {
		[error retain];
	}
	else {
		EVEMailingLists* mailingLists = [EVEMailingLists mailingListsWithKeyID:keyID vCode:vCode characterID:characterID error:nil];
		NSArray* readMessages = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[self messagesFilePath]]];
		NSArray* readNotifications = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[self notificationsFilePath]]];
		
		NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit fromDate:[NSDate date]];
		components.hour = 0;
		NSDate* today = [calendar dateFromComponents:components];
		NSDate* yesterday = [today dateByAddingTimeInterval:-60 * 60 * 24];
		[calendar release];
		
		inbox = [[NSMutableArray alloc] init];
		sent = [[NSMutableArray alloc] init];
		notifications = [[NSMutableArray alloc] initWithCapacity:eveNotifications.notifications.count];
		NSMutableSet* ids = [NSMutableSet set];
		
		NSDateFormatter* dateFormatterTime = [[NSDateFormatter alloc] init];
		NSDateFormatter* dateFormatterFull = [[NSDateFormatter alloc] init];
		[dateFormatterTime setDateFormat:@"HH:mm"];
		[dateFormatterFull setDateFormat:@"yyyy.MM.dd HH:mm"];
		
		for (EVEMailMessagesItem* item in mailMessages.mailMessages) {
			if (item.toCorpOrAllianceID)
				[ids addObject:[NSString stringWithFormat:@"%d", item.toCorpOrAllianceID]];
			[ids addObject:[NSString stringWithFormat:@"%d", item.senderID]];
			for (NSString* charID in item.toCharacterIDs)
				[ids addObject:charID];
			EUMailMessage* message = [EUMailMessage mailMessageWithMailBox:self];
			message.header = item;
			if (item.senderID == characterID) {
				[sent addObject:message];
				message.read = YES;
			}
			else {
				[inbox addObject:message];
				message.read = !readMessages || [readMessages containsObject:[NSNumber numberWithInteger:message.header.messageID]];
			}
			
			if ([item.sentDate laterDate:today] == item.sentDate)
				message.date = [NSString stringWithFormat:NSLocalizedString(@"Today at %@", nil), [dateFormatterTime stringFromDate:item.sentDate]];
			else if ([item.sentDate laterDate:yesterday] == item.sentDate)
				message.date = [NSString stringWithFormat:NSLocalizedString(@"Yesterday at %@", nil), [dateFormatterTime stringFromDate:item.sentDate]];
			else
				message.date = [dateFormatterFull stringFromDate:item.sentDate];
		}
		[dateFormatterTime release];
		[dateFormatterFull release];
		
		for (EVENotificationsItem* item in eveNotifications.notifications) {
			if (item.senderID)
				[ids addObject:[NSString stringWithFormat:@"%d", item.senderID]];
			EUNotification* notification = [EUNotification notificationWithMailBox:self];
			notification.header = item;
			[notifications addObject:notification];
		}
		
		NSMutableDictionary*characterNames = [NSMutableDictionary dictionary];
		NSArray* idsArray = [ids allObjects];
		NSRange range = NSMakeRange(0, MIN(idsArray.count, 250));
		while (range.length > 0) {
			EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:[idsArray subarrayWithRange:range] error:&error];
			if (characterName.characters.count > 0)
				[characterNames addEntriesFromDictionary:characterName.characters];
			range.location += range.length;
			range.length = idsArray.count - range.location;
			if (range.length > 250)
				range.length = 250;
		}
		
		/*if (characterName.characters.count == 0 && ids.count > 0) {
			NSMutableDictionary* characters = [NSMutableDictionary dictionary];
			NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
			for (NSString* charID in ids) {
				[operationQueue addOperationWithBlock:^{
					NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
					EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:[NSArray arrayWithObject:charID] error:nil];
					if (characterName.characters.count == 1) {
						@synchronized(characters) {
							[characters addEntriesFromDictionary:characterName.characters];
						}
					}
					[pool release];
				}];
			}
			[operationQueue waitUntilAllOperationsAreFinished];
			//EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:[ids allObjects] error:nil];
			//characterName.characters = characterName.characters;
		}*/
		
		for (EUMailMessage* message in [inbox arrayByAddingObjectsFromArray:sent]) {
			if (message.header.toCharacterIDs.count > 0) {
				NSMutableArray* names = [[NSMutableArray alloc] init];
				for (NSString* key in message.header.toCharacterIDs) {
					NSString* name = [characterNames valueForKey:key];
					if (name)
						[names addObject:name];
				}
				message.to = [names componentsJoinedByString:@", "];
				[names release];
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
			else if (message.header.toCorpOrAllianceID) {
				NSString* to = [characterNames valueForKey:[NSString stringWithFormat:@"%d", message.header.toCorpOrAllianceID]];
				if (to)
					message.to = to;
				else
					message.to = NSLocalizedString(@"Unknown corporation or alliance", nil);
			}
			if (!message.to)
				message.to = NSLocalizedString(@"Unknown recipient", nil);
			
			NSString* from = [characterNames valueForKey:[NSString stringWithFormat:@"%d", message.header.senderID]];
			if (from)
				message.from = from;
			else
				message.from = NSLocalizedString(@"Unknown sender", nil);
		}
		[inbox sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
		[sent sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
		
		for (EUNotification* notification in notifications) {
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
