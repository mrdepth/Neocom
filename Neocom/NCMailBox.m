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

@implementation NCMailBoxContact

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.contactID forKey:@"contactID"];
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

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.header forKey:@"header"];
	[aCoder encodeObject:self.recipients forKey:@"recipients"];
	[aCoder encodeObject:self.sender forKey:@"sender"];
	[aCoder encodeBool:self.read forKey:@"read"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.header = [aDecoder decodeObjectForKey:@"header"];
		self.recipients = [aDecoder decodeObjectForKey:@"recipients"];
		self.sender = [aDecoder decodeObjectForKey:@"sender"];
		self.read = [aDecoder decodeBoolForKey:@"read"];
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
- (void) loadMissingContacts:(NSDictionary*) existingContacts forMessages:(NSArray*) messages withApi:(EVEOnlineAPI*) api completionBlock:(void(^)(NSDictionary* contacts)) completionBlock progressBlock:(void(^)(float progress)) progressBlock;
- (void) clearCacheForMessage:(NCMailBoxMessage*) message;
@end

@implementation NCMailBox
@dynamic readedMessagesIDs;
@dynamic account;
@dynamic updateDate;

@synthesize cacheRecord = _cacheRecord;
@synthesize numberOfUnreadMessages = _numberOfUnreadMessages;
@synthesize cacheManagedObjectContext = _cacheManagedObjectContext;

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSArray* messages, NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	
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
		else
			loadDispatchGroup = _loadDispatchGroup;
	}
	if (load) {
		[self.managedObjectContext performBlock:^{
			EVEAPIKey* apiKey = self.account.eveAPIKey;
			EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:apiKey cachePolicy:cachePolicy];
			
			if (self.account.accountType == NCAccountTypeCorporate) {
				dispatch_group_leave(loadDispatchGroup);
				return;
			}
			
			NSString* uuid = self.account.uuid;
			
			NSSet* readedMessagesIDs = self.readedMessagesIDs;
			[self.cacheManagedObjectContext performBlock:^{
				NSArray* cachedMessages = _cacheRecord.data.data;
				if (!_cacheRecord) {
					_cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBox.%@", uuid]];
				}
				[self updateNumberOfUnreadMessages];
				
				[api mailMessagesWithCompletionBlock:^(EVEMailMessages *messageHeaders, NSError *error) {
					progress.completedUnitCount++;
					if (progressBlock)
						progressBlock(progress.fractionCompleted);
					NSMutableDictionary* contacts = [NSMutableDictionary new];
					
					if (messageHeaders) {
						NSMutableDictionary* messagesDic = [NSMutableDictionary new];
						for (NCMailBoxMessage* message in cachedMessages) {
							messagesDic[@(message.header.messageID)] = message;
							for (NCMailBoxContact* contact in message.recipients)
								contacts[@(contact.contactID)] = contact;
						}
						
						for (EVEMailMessagesItem* header in messageHeaders.messages) {
							NCMailBoxMessage* message = messagesDic[@(header.messageID)];
							if (!message) {
								NCMailBoxMessage* message = [NCMailBoxMessage new];
								message.header = header;
								messagesDic[@(message.header.messageID)] = message;
							}
						}
						
						NSArray* messages = [[messagesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"header.sentDate" ascending:NO]]];
						if (messages.count > NCMailBoxMessagesLimit) {
							NSArray* toDelete = [messages subarrayWithRange:NSMakeRange(NCMailBoxMessagesLimit, messages.count - NCMailBoxMessagesLimit)];
							for (NCMailBoxMessage* message in toDelete) {
								[self clearCacheForMessage:message];
							}
							
							messages = [messages subarrayWithRange:NSMakeRange(0, NCMailBoxMessagesLimit)];
						}
						
						for (NCMailBoxMessage* message in messages)
							message.read = [readedMessagesIDs containsObject:@(message.header.messageID)];

						[progress becomeCurrentWithPendingUnitCount:1];
						NSProgress* contractsProgress = [NSProgress progressWithTotalUnitCount:10];
						[progress resignCurrent];
						
						[contractsProgress becomeCurrentWithPendingUnitCount:10];
						[self loadMissingContacts:contacts forMessages:messages withApi:api completionBlock:^(NSDictionary *contacts) {
							NSDate* updateDate = [messageHeaders.eveapi localTimeWithServerTime:messageHeaders.eveapi.cacheDate];
							[self.managedObjectContext performBlock:^{
								self.updateDate = updateDate;
							}];
							
							[self.cacheManagedObjectContext performBlock:^{
								self.cacheRecord.data.data = messages;
								self.cacheRecord.date = updateDate;
								self.cacheRecord.expireDate = [messageHeaders.eveapi localTimeWithServerTime:messageHeaders.eveapi.cachedUntil];
								[self.cacheManagedObjectContext save:nil];
								[self updateNumberOfUnreadMessages];
								if (messages)
									dispatch_set_context(loadDispatchGroup, (__bridge_retained void*)@{@"messages":messages});
								dispatch_group_leave(loadDispatchGroup);
								@synchronized(self) {
									_loadDispatchGroup = nil;
								}
							}];
						} progressBlock:^(float p) {
							@synchronized(contractsProgress) {
								contractsProgress.completedUnitCount = p * 10;
							}
							if (progressBlock)
								progressBlock(progress.fractionCompleted);
						}];
						[contractsProgress resignCurrent];
						
					}
					else {
						if (error)
							dispatch_set_context(loadDispatchGroup, (__bridge_retained void*)@{@"error":error});
						dispatch_group_leave(loadDispatchGroup);
						@synchronized(self) {
							_loadDispatchGroup = nil;
						}
					}
				} progressBlock:nil];
			}];
		}];
	}
	
	dispatch_group_notify(loadDispatchGroup, dispatch_get_main_queue(), ^{
		NSDictionary* result = (__bridge NSDictionary*) dispatch_get_context(loadDispatchGroup);
		completionBlock(result[@"messages"], result[@"error"]);
	});
}

- (void) markAsRead:(NSArray*) messages {
	[self.managedObjectContext performBlock:^{
		NSMutableSet* set = [[NSMutableSet alloc] initWithSet:self.readedMessagesIDs];
		for (NCMailBoxMessage* message in messages)
			[set addObject:@(message.header.messageID)];
		self.readedMessagesIDs = set;
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
		NSString* uuid = self.account.uuid;
		[self.cacheManagedObjectContext performBlock:^{
			if (!_cacheRecord) {
				_cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBox.%@", uuid]];
			}
			
			NSArray* messages = _cacheRecord.data.data;
			for (NCMailBoxMessage* message in messages)
				message.read = [set containsObject:@(message.header.messageID)];
			[self updateNumberOfUnreadMessages];
			
			if ([_cacheRecord.managedObjectContext hasChanges])
				[_cacheRecord.managedObjectContext save:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:NCMailBoxDidUpdateNotification object:self];
			});
		}];
	}];
}

- (void) loadMessagesWithCompletionBlock:(void(^)(NSArray* messages, NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	if (!_cacheRecord) {
		[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy
					completionBlock:^(NSArray* messages, NSError *error) {
						completionBlock(messages, error);
					} progressBlock:progressBlock];
	}
	else {
		[_cacheRecord.managedObjectContext performBlock:^{
			NSArray* messages = _cacheRecord.data.data;
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(messages, nil);
			});
		}];
	}
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	if (!_cacheManagedObjectContext)
		_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
	return _cacheManagedObjectContext;
}

- (void) loadBodyForMessage:(NCMailBoxMessage*) message withCompletionBlock:(void(^)(EVEMailBodiesItem* body, NSError* error)) completionBlock {
	if (!message.body) {
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:[NSString stringWithFormat:@"NCMailBoxMessage.%d", message.header.messageID]];
			message.body = cacheRecord.data.data;
			if (!message.body) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.account.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] mailBodiesWithIDs:@[@(message.header.messageID)]
																																  completionBlock:^(EVEMailBodies *result, NSError *error) {
																																	  if (result) {
																																		  message.body = result.messages[0];
																																		  [cacheRecord.managedObjectContext performBlock:^{
																																			  cacheRecord.date = [result.eveapi localTimeWithServerTime:result.eveapi.cacheDate];
																																			  cacheRecord.expireDate = [result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil];
																																			  cacheRecord.data.data = message.body;
																																			  [cacheRecord.managedObjectContext save:nil];
																																		  }];
																																	  }
																																	  dispatch_async(dispatch_get_main_queue(), ^{
																																		  completionBlock(message.body, error);
																																	  });
																																  } progressBlock:nil];
				}];
			}
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(message.body, nil);
				});
		}];
	}
	else if (completionBlock)
		completionBlock(message.body, nil);
}

#pragma mark - Private

- (void) updateNumberOfUnreadMessages {
	NSArray* messages = _cacheRecord.data.data;
	NSInteger numberOfUnreadMessages = 0;
	for (NCMailBoxMessage* message in messages) {
		if (![message isRead])
			numberOfUnreadMessages++;
	}
	self.numberOfUnreadMessages = numberOfUnreadMessages;
}

- (void) loadMissingContacts:(NSDictionary*) existingContacts forMessages:(NSArray*) messages withApi:(EVEOnlineAPI*) api completionBlock:(void(^)(NSDictionary* contacts)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
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
		
		NCMailBoxContact* sender = contacts[@(message.header.senderID)];
		if (!sender) {
			sender = existingContacts[@(message.header.senderID)];
			if (!sender) {
				sender = [NCMailBoxContact new];
				sender.contactID = message.header.senderID;
				sender.type = NCMailBoxContactTypeCharacter;
				sender.name = message.header.senderName;
				contacts[@(sender.contactID)] = sender;
			}
		}
		message.sender = sender;
	}
	
	dispatch_group_t finishDispatchGroup = dispatch_group_create();
	
	NSProgress* totalProgress = [NSProgress progressWithTotalUnitCount:2];
	NSArray* allIDs = [ids allKeys];
	NSRange range = NSMakeRange(0, MIN(allIDs.count, 250));
	
	[totalProgress becomeCurrentWithPendingUnitCount:1];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:allIDs.count];
	[totalProgress resignCurrent];
	while (range.length > 0) {
		dispatch_group_enter(finishDispatchGroup);
		NSRange r = range;
		[api characterNameWithIDs:[allIDs subarrayWithRange:r] completionBlock:^(EVECharacterName *result, NSError *error) {
			for (EVECharacterIDItem* character in result.characters) {
				NCMailBoxContact* contact = ids[@(character.characterID)];
				contact.name = character.name;
			}
			dispatch_group_leave(finishDispatchGroup);
			@synchronized(progress) {
				progress.completedUnitCount = r.location + r.length;
			}
			if (progressBlock)
				progressBlock(totalProgress.fractionCompleted);
		} progressBlock:nil];
		
		range.location += range.length;
		range.length = allIDs.count - range.location;
		if (range.length > 250)
			range.length = 250;
	}
	
	if (mailingListIDs.count > 0) {
		dispatch_group_leave(finishDispatchGroup);
		[api mailingListsWithCompletionBlock:^(EVEMailingLists *result, NSError *error) {
			for (EVEMailingListsItem* mailingList in result.mailingLists) {
				NCMailBoxContact* contact = mailingListIDs[@(mailingList.listID)];
				contact.name = mailingList.displayName ? mailingList.displayName : NSLocalizedString(@"Unknown Mailing List", nil);
			}
			totalProgress.completedUnitCount++;
			if (progressBlock)
				progressBlock(totalProgress.fractionCompleted);
			dispatch_group_leave(finishDispatchGroup);
		} progressBlock:nil];
	}
	else {
		totalProgress.completedUnitCount++;
		if (progressBlock)
			progressBlock(totalProgress.fractionCompleted);
	}
	
	dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
		completionBlock(contacts);
	});
}

- (void) clearCacheForMessage:(NCMailBoxMessage*) message {
	[self.cacheManagedObjectContext performBlock:^{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"recordID == %@", [NSString stringWithFormat:@"NCMailBoxMessage.%d", message.header.messageID]];
		
		NSArray *fetchedObjects = [self.cacheManagedObjectContext executeFetchRequest:fetchRequest error:nil];
		for (NCCacheRecord* record in fetchedObjects)
			[self.cacheManagedObjectContext deleteObject:record];
		[self.cacheManagedObjectContext save:nil];
	}];
}

@end
