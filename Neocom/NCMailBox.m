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

- (void) loadBodyWithCompletionBlock:(void(^)(EVEMailBodiesItem* body, NSError* error)) completionBlock {
	if (!_body) {
		[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
			 NCCacheRecord* cacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBoxMessage.%d", self.header.messageID]];
			_body = cacheRecord.data.data;
			if (!_body) {
				[self.mailBox.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.mailBox.account.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] mailBodiesWithIDs:@[@(self.header.messageID)]
																																  completionBlock:^(EVEMailBodies *result, NSError *error) {
																																	  if (result) {
																																		  _body = result.messages[0];
																																		  [cacheRecord.managedObjectContext performBlock:^{
																																			  cacheRecord.date = result.eveapi.cacheDate;
																																			  cacheRecord.expireDate = result.eveapi.cachedUntil;
																																			  cacheRecord.data.data = _body;
																																			  [cacheRecord.managedObjectContext save:nil];
																																		  }];
																																	  }
																																	  dispatch_async(dispatch_get_main_queue(), ^{
																																		  completionBlock(_body, error);
																																	  });
																																  } progressBlock:nil];
				}];
			}
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(_body, nil);
				});
		}];
	}
	else if (completionBlock)
		completionBlock(_body, nil);
}

- (void) clearCache {
	NCCache* cache = [NCCache sharedCache];
	[cache.managedObjectContext performBlock:^{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"recordID == %@", [NSString stringWithFormat:@"NCMailBoxMessage.%d", self.header.messageID]];
		
		NSArray *fetchedObjects = [cache.managedObjectContext executeFetchRequest:fetchRequest error:nil];
		for (NCCacheRecord* record in fetchedObjects)
			[cache.managedObjectContext deleteObject:record];
		[cache saveContext];
	}];
}

- (BOOL) isRead {
	return [self.mailBox.readedMessagesIDs containsObject:@(self.header.messageID)];
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.header)
		[aCoder encodeObject:self.header forKey:@"header"];
	if (self.recipients)
		[aCoder encodeObject:self.recipients forKey:@"recipients"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.header = [aDecoder decodeObjectForKey:@"header"];
		self.recipients = [aDecoder decodeObjectForKey:@"recipients"];
	}
	return self;
}

@end

@interface NCMailBox() {
	dispatch_group_t _loadDispatchGroup;
}
@property (nonatomic, strong) NCCacheRecord* cacheRecord;
@property (nonatomic, assign, readwrite) NSInteger numberOfUnreadMessages;
- (void) updateNumberOfUnreadMessages;
- (void) loadMissingContacts:(NSDictionary*) existingContacts forMessages:(NSArray*) messages withCompletionBlock:(void(^)(NSDictionary* contacts)) completionBlock api:(EVEOnlineAPI*) api;
@end

@implementation NCMailBox
@dynamic readedMessagesIDs;
@dynamic account;
@dynamic updateDate;

@synthesize cacheRecord = _cacheRecord;
@synthesize numberOfUnreadMessages = _numberOfUnreadMessages;

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSArray* messages, NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	
	BOOL load = NO;
	dispatch_group_t loadDispatchGroup;
	@synchronized(self) {
		if (!_loadDispatchGroup) {
			_loadDispatchGroup = dispatch_group_create();
			load = YES;
			loadDispatchGroup = _loadDispatchGroup;
			dispatch_group_enter(loadDispatchGroup);
			dispatch_set_finalizer_f(loadDispatchGroup, (dispatch_function_t) &CFRelease);
		}
	}
	if (load) {
		
	}
	
	dispatch_group_notify(loadDispatchGroup, dispatch_get_main_queue(), ^{
		NSDictionary* result = (__bridge NSDictionary*) dispatch_get_context(loadDispatchGroup);
		completionBlock(result[@"messages"], result[@"error"]);
	});
	
	[self.managedObjectContext performBlock:^{
		EVEAPIKey* apiKey = self.account.eveAPIKey;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:apiKey cachePolicy:cachePolicy];

		if (self.account.accountType == NCAccountTypeCorporate) {
			dispatch_group_leave(loadDispatchGroup);
			return;
		}

		NCCache* cache = [NCCache sharedCache];
		NSString* uuid = self.account.uuid;
		
		[cache.managedObjectContext performBlock:^{
			NCMailBoxCacheData* data = _cacheRecord.data.data;
			if (!_cacheRecord) {
				_cacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBox.%@", uuid]];
				for (NCMailBoxMessage* message in data.messages)
					message.mailBox = self;
			}
			[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
			
			[api mailMessagesWithCompletionBlock:^(EVEMailMessages *messageHeaders, NSError *error) {
				if (messageHeaders) {
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
					
					[self loadMissingContacts:data.contacts forMessages:messages withCompletionBlock:^(NSDictionary *contacts) {
						NCMailBoxCacheData* data = [NCMailBoxCacheData new];
						
						data.messages = messages;
						data.contacts = contacts;
						
						self.updateDate = messageHeaders.eveapi.cacheDate;
						[cache.managedObjectContext performBlock:^{
							self.cacheRecord.data.data = data;
							self.cacheRecord.date = self.updateDate;
							self.cacheRecord.expireDate = messageHeaders.eveapi.cachedUntil;
							[cache.managedObjectContext save:nil];
						}];
						if (data.messages)
							dispatch_set_context(loadDispatchGroup, (__bridge_retained void*)@{@"messages":data.messages});
						dispatch_group_leave(loadDispatchGroup);
						
						[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
					} api:api];
				}
				else {
					if (error)
						dispatch_set_context(loadDispatchGroup, (__bridge_retained void*)@{@"error":error});
					dispatch_group_leave(loadDispatchGroup);
				}
			} progressBlock:nil];
		}];
	}];
}

- (void) markAsRead:(NSArray*) messages {
	@synchronized(self) {
		NSMutableSet* set = [[NSMutableSet alloc] initWithSet:self.readedMessagesIDs];
		for (NCMailBoxMessage* message in messages)
			[set addObject:@(message.header.messageID)];
		
		[self.managedObjectContext performBlockAndWait:^{
			self.readedMessagesIDs = set;
//			if ([self.managedObjectContext hasChanges])
//				[self.managedObjectContext save:nil];
		}];
		[self performSelectorOnMainThread:@selector(updateNumberOfUnreadMessages) withObject:nil waitUntilDone:NO];
	}
}

- (void) loadMessagesWithCompletionBlock:(void(^)(NSArray* messages, NSError* error)) completionBlock {
	if (!_cacheRecord) {
		[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy
					completionBlock:^(NSArray* messages, NSError *error) {
						completionBlock(messages, error);
					} progressBlock:nil];
	}
	else {
		[_cacheRecord.managedObjectContext performBlock:^{
			NCMailBoxCacheData* data = _cacheRecord.data.data;
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(data.messages, nil);
			});
		}];
	}
}

#pragma mark - Private

- (void) updateNumberOfUnreadMessages {
	[_cacheRecord.managedObjectContext performBlock:^{
		NCMailBoxCacheData* data = _cacheRecord.data.data;
		[self.managedObjectContext performBlock:^{
			NSInteger numberOfUnreadMessages = 0;
			for (NCMailBoxMessage* message in data.messages) {
				if (![message isRead])
					numberOfUnreadMessages++;
			}
			self.numberOfUnreadMessages = numberOfUnreadMessages;
		}];
	}];
}

- (void) loadMissingContacts:(NSDictionary*) existingContacts forMessages:(NSArray*) messages withCompletionBlock:(void(^)(NSDictionary* contacts)) completionBlock api:(EVEOnlineAPI*) api{
	NSMutableDictionary* ids = [NSMutableDictionary new];
	NSMutableDictionary* contacts = [NSMutableDictionary new];
	NSMutableDictionary* mailingListIDs = [NSMutableDictionary new];
	
	for (NCMailBoxMessage* message in messages) {
		NSMutableArray* recipients = [NSMutableArray new];
		
		for (NSNumber* charID in message.header.toCharacterIDs) {
			NCMailBoxContact* recipient = contacts[charID];
			if (!recipient) {
				recipient = existingContacts[charID];
				
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
				recipient = existingContacts[mailingListID];
				
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
				recipient = existingContacts[@(message.header.toCorpOrAllianceID)];
				
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
	}
	
	NSMutableArray* operations = [NSMutableArray new];
	
	NSArray* allIDs = [ids allKeys];
	NSRange range = NSMakeRange(0, MIN(allIDs.count, 250));
	while (range.length > 0) {
		[operations addObject:[api characterNameWithIDs:[allIDs subarrayWithRange:range] completionBlock:^(EVECharacterName *result, NSError *error) {
			for (EVECharacterIDItem* character in result.characters) {
				NCMailBoxContact* contact = ids[@(character.characterID)];
				contact.name = character.name;
			}
		} progressBlock:nil]];

		range.location += range.length;
		range.length = allIDs.count - range.location;
		if (range.length > 250)
			range.length = 250;
	}
	
	if (mailingListIDs.count > 0) {
		[operations addObject:[api mailingListsWithCompletionBlock:^(EVEMailingLists *result, NSError *error) {
			for (EVEMailingListsItem* mailingList in result.mailingLists) {
				NCMailBoxContact* contact = mailingListIDs[@(mailingList.listID)];
				contact.name = mailingList.displayName ? mailingList.displayName : NSLocalizedString(@"Unknown Mailing List", nil);
			}
		} progressBlock:nil]];
	}
	if (operations.count > 0) {
		NSOperation* operation = [[AFHTTPRequestOperation batchOfRequestOperations:operations progressBlock:nil completionBlock:^void(NSArray * operations) {
			completionBlock(contacts);
		}] lastObject];
		[api.httpRequestOperationManager.operationQueue addOperation:operation];
	}
	else
		completionBlock(contacts);
}

@end
