//
//  NCMailBox.m
//  Neocom
//
//  Created by Артем Шиманский on 24.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMailBox.h"
#import "NCAccount.h"
#import "NCStorage.h"
#import "NCCache.h"

#define NCMailBoxMessagesLimit 200

@interface NCMailBoxCacheData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* messages;
@property (nonatomic, strong) NSDictionary* contacts;
@end

@implementation NCMailBoxCacheData

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.messages)
		[aCoder encodeObject:self.messages forKey:@"messages"];
	if (self.contacts)
		[aCoder encodeObject:self.contacts forKey:@"contacts"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.messages = [aDecoder decodeObjectForKey:@"messages"];
		self.contacts = [aDecoder decodeObjectForKey:@"contacts"];
	}
	return self;
}

@end

@implementation NCMailBoxContact

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.contactID forKey:@"contactID"];
	if (self.name)
		[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeInt32:self.type forKey:@"type"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.contactID = [aDecoder decodeInt32ForKey:@"contactID"];
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.type = [aDecoder decodeInt32ForKey:@"type"];
	}
	return self;
}

@end

@implementation NCMailBoxMessage

- (EVEMailBodiesItem*) body {
	if (!_body) {
		__block NCCacheRecord* cacheRecord;
		[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
			 cacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBoxMessage.%d", self.header.messageID]];
			[cacheRecord data];
		}];
		
		if (cacheRecord.data.data)
			_body = cacheRecord.data.data;
		else {
			if (![NSThread isMainThread]) {
				EVEMailBodies* bodies = [EVEMailBodies mailBodiesWithKeyID:self.mailBox.account.apiKey.keyID
																	 vCode:self.mailBox.account.apiKey.vCode
															   cachePolicy:NSURLRequestUseProtocolCachePolicy
															   characterID:self.mailBox.account.characterID
																	   ids:@[@(self.header.messageID)]
																	 error:nil
														   progressHandler:nil];
				if (bodies.messages.count > 0) {
					_body = bodies.messages[0];
					NCCache* cache = [NCCache sharedCache];
					[cache.managedObjectContext performBlockAndWait:^{
						cacheRecord.date = bodies.cacheDate;
						cacheRecord.expireDate = bodies.cacheExpireDate;
						cacheRecord.data.data = _body;
						[cache saveContext];
					}];
				}
			}
		}
	}
	return _body;
}

- (void) clearCache {
	NCCache* cache = [NCCache sharedCache];
	[cache.managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSManagedObjectContext* context = [[NCCache sharedCache] managedObjectContext];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", [NSString stringWithFormat:@"NCMailBoxMessage.%d", self.header.messageID]]];
		
		NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
		for (NCCacheRecord* record in fetchedObjects)
			[cache.managedObjectContext deleteObject:record];
		[cache saveContext];
	}];
}

- (BOOL) isRead {
	return [self.mailBox.readedMessagesIDs containsObject:@(self.header.messageID)] || self.header.read;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.header)
		[aCoder encodeObject:self.header forKey:@"header"];
	if (self.sender)
		[aCoder encodeObject:self.sender forKey:@"sender"];
	if (self.recipients)
		[aCoder encodeObject:self.recipients forKey:@"recipients"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.header = [aDecoder decodeObjectForKey:@"header"];
		self.sender = [aDecoder decodeObjectForKey:@"sender"];
		self.recipients = [aDecoder decodeObjectForKey:@"recipients"];
	}
	return self;
}

@end

@interface NCMailBox()
@property (nonatomic, strong) NCCacheRecord* cacheRecord;
@property (nonatomic, assign, readwrite) NSInteger numberOfUnreadMessages;
- (void) updateNumberOfUnreadMessages;
@end

@implementation NCMailBox
@dynamic readedMessagesIDs;
@dynamic account;
@dynamic updateDate;

@synthesize messages = _messages;
@synthesize cacheRecord = _cacheRecord;
@synthesize numberOfUnreadMessages = _numberOfUnreadMessages;

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy inTask:(NCTask*) task {
	__block NCAccount* account = nil;
	[self.managedObjectContext performBlockAndWait:^{
		account = self.account;
	}];

	if (account.accountType == NCAccountTypeCorporate)
		return;
	
	NCMailBoxCacheData* data = self.cacheRecord.data.data;
	
	EVEMailMessages* messageHeaders = [EVEMailMessages mailMessagesWithKeyID:account.apiKey.keyID
																	   vCode:account.apiKey.vCode
																 cachePolicy:cachePolicy
																 characterID:account.characterID
																	   error:nil
															 progressHandler:^(CGFloat progress, BOOL *stop) {
															 }];
	if (!messageHeaders)
		return;
	
	NSMutableDictionary* messagesDic = [NSMutableDictionary new];
	for (NCMailBoxMessage* message in data.messages)
		messagesDic[@(message.header.messageID)] = message;

	for (EVEMailMessagesItem* header in messageHeaders.mailMessages) {
		NCMailBoxMessage* message = messagesDic[@(header.messageID)];
		if (!message) {
			NCMailBoxMessage* message = [NCMailBoxMessage new];
			message.header = header;
			message.mailBox = self;
			messagesDic[@(message.header.messageID)] = message;
		}
	}
	
	NSArray* messages = [[messagesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
	if (messages.count > NCMailBoxMessagesLimit) {
		NSArray* toDelete = [messages subarrayWithRange:NSMakeRange(NCMailBoxMessagesLimit, messages.count - NCMailBoxMessagesLimit)];
		for (NCMailBoxMessage* message in toDelete) {
			[message clearCache];
		}
		
		messages = [messages subarrayWithRange:NSMakeRange(0, NCMailBoxMessagesLimit)];
	}
	
	NSMutableDictionary* ids = [NSMutableDictionary new];
	NSMutableDictionary* contacts = [NSMutableDictionary new];
	NSMutableDictionary* mailingListIDs = [NSMutableDictionary new];

	for (NCMailBoxMessage* message in messages) {
		NSMutableArray* recipients = [NSMutableArray new];
		
		for (NSNumber* charID in message.header.toCharacterIDs) {
			NCMailBoxContact* recipient = contacts[charID];
			if (!recipient) {
				recipient = data.contacts[charID];
				
				if (!recipient.name) {
					recipient = [NCMailBoxContact new];
					recipient.contactID = [charID intValue];
					recipient.type = NCMailBoxContactTypeCharacter;
					ids[charID] = recipient;
				}
				contacts[@(recipient.contactID)] = recipient;
			}
			[recipients addObject:recipient];
		}
		for (NSNumber* mailingListID in message.header.toListID) {
			NCMailBoxContact* recipient = contacts[mailingListID];
			if (!recipient) {
				recipient = data.contacts[mailingListID];
			
				if (!recipient.name) {
					recipient = [NCMailBoxContact new];
					recipient.contactID = [mailingListID intValue];
					recipient.type = NCMailBoxContactTypeMailingList;
					mailingListIDs[mailingListID] = recipient;
				}
				contacts[@(recipient.contactID)] = recipient;
			}
			[recipients addObject:recipient];
		}
		if (message.header.toCorpOrAllianceID) {
			NCMailBoxContact* recipient = contacts[@(message.header.toCorpOrAllianceID)];
			if (!recipient) {
				recipient = data.contacts[@(message.header.toCorpOrAllianceID)];

				if (!recipient) {
					recipient = [NCMailBoxContact new];
					recipient.contactID = message.header.toCorpOrAllianceID;
					recipient.type = NCMailBoxContactTypeCorporation;
					ids[@(message.header.toCorpOrAllianceID)] = recipient;
				}
				contacts[@(recipient.contactID)] = recipient;
			}
			[recipients addObject:recipient];
		}
		message.recipients = recipients;
		
		NCMailBoxContact* sender = contacts[@(message.header.senderID)];
		if (!sender) {
			sender = data.contacts[@(message.header.senderID)];
			if (!sender) {
				sender = [NCMailBoxContact new];
				sender.contactID = message.header.senderID;
				
				if (message.header.senderTypeID > 0) {
					sender.type = NCMailBoxContactTypeCharacter;
					ids[@(message.header.senderID)] = sender;
				}
				else {
					sender.type = NCMailBoxContactTypeMailingList;
					mailingListIDs[@(message.header.senderTypeID)] = sender;
				}
				contacts[@(sender.contactID)] = sender;
			}
		}
		message.sender = sender;
	}

	NSArray* allIDs = [ids allKeys];
	NSRange range = NSMakeRange(0, MIN(allIDs.count, 250));
	while (range.length > 0) {
		EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:[allIDs subarrayWithRange:range]
																	 cachePolicy:cachePolicy
																		   error:nil
																 progressHandler:^(CGFloat progress, BOOL *stop) {
																 }];
		
		[characterName.characters enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSString* name, BOOL *stop) {
			NCMailBoxContact* contact = ids[key];
			contact.name = name;
		}];
		
		range.location += range.length;
		range.length = allIDs.count - range.location;
		if (range.length > 250)
			range.length = 250;
	}
	
	if (mailingListIDs.count > 0) {
		EVEMailingLists* mailingLists = [EVEMailingLists mailingListsWithKeyID:account.apiKey.keyID
																		 vCode:account.apiKey.vCode
																   cachePolicy:cachePolicy
																   characterID:account.characterID
																		 error:nil
															   progressHandler:^(CGFloat progress, BOOL *stop) {
															   }];
		for (EVEMailingListsItem* mailingList in mailingLists.mailingLists) {
			NCMailBoxContact* contact = mailingListIDs[@(mailingList.listID)];
			contact.name = mailingList.displayName ? mailingList.displayName : NSLocalizedString(@"Unknown Mailing List", nil);
		}
	}
	
	data = [NCMailBoxCacheData new];
	
	data.messages = messages;
	data.contacts = contacts;
	
	NCCache* cache = [NCCache sharedCache];
	self.updateDate = messageHeaders.cacheDate;
	[cache.managedObjectContext performBlockAndWait:^{
		self.cacheRecord.data.data = data;
		self.cacheRecord.date = self.updateDate;
		self.cacheRecord.expireDate = messageHeaders.cacheExpireDate;
		[cache saveContext];
	}];
	[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
}

- (void) markAsRead:(NSArray*) messages {
	@synchronized(self) {
		NSMutableSet* set = [[NSMutableSet alloc] initWithSet:self.readedMessagesIDs];
		for (NCMailBoxMessage* message in messages)
			[set addObject:@(message.header.messageID)];
		
		NCStorage* storage = [NCStorage sharedStorage];
		[storage.managedObjectContext performBlockAndWait:^{
			self.readedMessagesIDs = set;
			[storage saveContext];
		}];
		[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
	}
}

- (NSArray*) messages {
	@synchronized(self) {
		NCMailBoxCacheData* data = self.cacheRecord.data.data;
		if (!data && ![NSThread isMainThread]) {
			[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy inTask:nil];
			data = self.cacheRecord.data.data;
		}
		return data.messages;
	}
}

#pragma mark - Private

- (NCCacheRecord*) cacheRecord {
	if (!_cacheRecord) {
		__block NCAccount* account = nil;
		[self.managedObjectContext performBlockAndWait:^{
			account = self.account;
		}];

		[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
			_cacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBox.%@", account.uuid]];
			for (NCMailBoxMessage* message in [_cacheRecord.data.data messages]) {
				message.mailBox = self;
			}
		}];
		[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
	}
	return _cacheRecord;
}

- (void) updateNumberOfUnreadMessages {
	NSInteger numberOfUnreadMessages = 0;
	NCMailBoxCacheData* data = _cacheRecord.data.data;
	for (NCMailBoxMessage* message in data.messages) {
		if (![message isRead])
			numberOfUnreadMessages++;
	}
	self.numberOfUnreadMessages = numberOfUnreadMessages;
}

@end
