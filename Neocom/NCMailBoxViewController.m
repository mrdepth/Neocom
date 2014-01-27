//
//  NCMailBoxViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMailBoxViewController.h"
#import "NCStorage.h"
#import "NSArray+Neocom.h"
#import "NCMessageCell.h"
#import "NSDate+Neocom.h"
#import "NCMailBoxMessageViewController.h"

@interface NCMailBoxViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* messages;

//- (void) loadDataInTask:(NCTask*) task;
@end

@implementation NCMailBoxViewControllerData

/*- (void) loadDataInTask:(NCTask *)task {
	NSMutableArray* sent = [NSMutableArray new];
	NSMutableArray* inbox = [NSMutableArray new];
	NSMutableDictionary* corps = [NSMutableDictionary new];
	NSMutableDictionary* mailingLists = [NSMutableDictionary new];
	
	
	NSInteger myID = self.mailBox.account.characterID;
	for (NCMailBoxMessage* message in self.mailBox.messages) {
		BOOL inInbox = NO;
		
		if (message.sender.contactID == myID)
			[sent addObject:message];
		else {
			for (NCMailBoxContact* contact in message.recipients) {
				if (contact.type == NCMailBoxContactTypeCharacter)
					inInbox = YES;
				else if (contact.type == NCMailBoxContactTypeCorporation) {
					NSDictionary* corp = corps[@(contact.contactID)];
					if (!corp)
						corps[@(contact.contactID)] = corp = @{@"contact": contact, @"messages": [NSMutableArray new]};
					[corp[@"messages"] addObject:message];
				}
				else if (contact.type == NCMailBoxContactTypeMailingList) {
					NSDictionary* mailingList = mailingLists[@(contact.contactID)];
					if (!mailingList)
						mailingLists[@(contact.contactID)] = mailingList = @{@"contact": contact, @"messages": [NSMutableArray new]};
					[mailingList[@"messages"] addObject:message];
				}
			}
		}
		if (inInbox)
			[inbox addObject:message];
	}
	
	NSInteger (^numberOfUnreadMessages)(NSArray*) = ^(NSArray* messages) {
		NSInteger numberOfUnreadMessages = 0;
		for (NCMailBoxMessage* message in messages)
			if (![message isRead])
				numberOfUnreadMessages++;
		return numberOfUnreadMessages;
	};
	
	NSMutableArray* sections = [NSMutableArray new];
	
	NSInteger n = numberOfUnreadMessages(inbox);
	NSString* title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Inbox (%d)", nil), n] : NSLocalizedString(@"Inbox", nil);
	[sections addObject:@{@"title": title, @"rows": inbox}];
	
	for (NSDictionary* dictionary in @[corps, mailingLists]) {
		NSArray* values = [[dictionary allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contact.name" ascending:YES]]];
		for (NSDictionary* dic in values) {
			NSInteger n = numberOfUnreadMessages(dic[@"messages"]);
			NSString* title = n > 0 ? [NSString stringWithFormat:@"%@ (%d)", [dic[@"contact"] name], n] : [dic[@"contact"] name];
			[sections addObject:@{@"title": title, @"rows": dic[@"messages"]}];
		}
	}
	
	n = numberOfUnreadMessages(sent);
	title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Sent (%d)", nil), n] : NSLocalizedString(@"Sent", nil);
	[sections addObject:@{@"title": title, @"rows": sent}];
	self.sections = sections;
}*/

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.messages)
		[aCoder encodeObject:self.messages forKey:@"messages"];
//	[aCoder encodeObject:[self.mailBox.objectID URIRepresentation] forKey:@"mailBox"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
/*		NSURL* url = [aDecoder decodeObjectForKey:@"mailBox"];
		if (url) {
			NCStorage* storage = [NCStorage sharedStorage];
			[storage.managedObjectContext performBlockAndWait:^{
				NSManagedObjectID* objectID = [storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
				self.mailBox = (NCMailBox*) [storage.managedObjectContext objectWithID:objectID];
			}];
		}*/
		self.messages = [aDecoder decodeObjectForKey:@"messages"];
//		for (NSDictionary* section in self.sections)
//			for (NCMailBoxMessage* message in section[@"rows"])
//				message.mailBox = self.mailBox;
	}
	return self;
}

@end

@interface NCMailBoxViewController ()
@property (nonatomic, strong) NCMailBox* mailBox;
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCMailBoxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
	self.mailBox = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	NCAccount* account = [NCAccount currentAccount];
	self.mailBox = account.mailBox;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([NSThread isMainThread]) {
/*		NCMailBoxViewControllerData* data = [NCMailBoxViewControllerData new];
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 data.mailBox = self.mailBox;
												 //[data loadDataInTask:task];
											 }
								 completionHandler:^(NCTask *task) {
									 if (!task.isCancelled) {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }];*/
		[self update];
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCMailBoxMessageViewController"]) {
		NCMailBoxMessageViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.message = [(NCMessageCell*) sender message];
	}
}

- (IBAction)markAsRead:(id)sender {
	NCMailBoxViewControllerData* data = self.data;
	[self.mailBox markAsRead:data.messages];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//NCMailBoxViewControllerData* data = self.data;
	return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	//NCMailBoxViewControllerData* data = self.data;
	return self.sections[section][@"title"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	//NCMailBoxViewControllerData* data = self.data;
	NCMailBoxMessage* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	static NSString *cellIdentifier = @"Cell";
	NCMessageCell* cell = (NCMessageCell*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.subjectLabel.text = row.header.title;
	BOOL isRead = [row isRead];
	cell.subjectLabel.font = isRead ? [UIFont systemFontOfSize:cell.subjectLabel.font.pointSize] : [UIFont boldSystemFontOfSize:cell.subjectLabel.font.pointSize];
	cell.subjectLabel.textColor = isRead ? [UIColor lightTextColor] : [UIColor whiteColor];
	cell.dateLabel.text = [row.header.sentDate messageTimeLocalizedString];
	cell.senderLabel.text = [NSString stringWithFormat:NSLocalizedString(@"from %@", nil), row.sender.name.length > 0 ? row.sender.name : NSLocalizedString(@"Unknown", nil)];
	cell.message = row;
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCMessageCell* cell = (NCMessageCell*) [self tableView:tableView cellForRowAtIndexPath:indexPath];
	CGRect frame = cell.frame;
	frame.size.width = self.tableView.frame.size.width;
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return CGRectGetMaxY(cell.senderLabel.frame);
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account || account.accountType == NCAccountTypeCorporate) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	self.mailBox = account.mailBox;
	NCMailBoxViewControllerData* data = [NCMailBoxViewControllerData new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [account.mailBox reloadDataWithCachePolicy:cachePolicy inTask:task];
											 //data.mailBox = account.mailBox;
											 data.messages = account.mailBox.messages;
											 //[data loadDataInTask:task];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:account.mailBox.updateDate expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) update {
	[super update];
	NCMailBoxViewControllerData* data = self.data;
	NCMailBox* mailBox = self.mailBox;

	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableArray* sent = [NSMutableArray new];
											 NSMutableArray* inbox = [NSMutableArray new];
											 NSMutableDictionary* corps = [NSMutableDictionary new];
											 NSMutableDictionary* mailingLists = [NSMutableDictionary new];
											 
											 NSInteger myID = mailBox.account.characterID;
											 for (NCMailBoxMessage* message in data.messages) {
												 if (!message.mailBox)
													 message.mailBox = mailBox;
												 BOOL inInbox = NO;
												 
												 if (message.sender.contactID == myID)
													 [sent addObject:message];
												 else {
													 for (NCMailBoxContact* contact in message.recipients) {
														 if (contact.type == NCMailBoxContactTypeCharacter)
															 inInbox = YES;
														 else if (contact.type == NCMailBoxContactTypeCorporation) {
															 NSDictionary* corp = corps[@(contact.contactID)];
															 if (!corp)
																 corps[@(contact.contactID)] = corp = @{@"contact": contact, @"messages": [NSMutableArray new]};
															 [corp[@"messages"] addObject:message];
														 }
														 else if (contact.type == NCMailBoxContactTypeMailingList) {
															 NSDictionary* mailingList = mailingLists[@(contact.contactID)];
															 if (!mailingList)
																 mailingLists[@(contact.contactID)] = mailingList = @{@"contact": contact, @"messages": [NSMutableArray new]};
															 [mailingList[@"messages"] addObject:message];
														 }
													 }
												 }
												 if (inInbox)
													 [inbox addObject:message];
											 }
											 
											 NSInteger (^numberOfUnreadMessages)(NSArray*) = ^(NSArray* messages) {
												 NSInteger numberOfUnreadMessages = 0;
												 for (NCMailBoxMessage* message in messages)
													 if (![message isRead])
														 numberOfUnreadMessages++;
												 return numberOfUnreadMessages;
											 };
											 
											 
											 NSInteger n = numberOfUnreadMessages(inbox);
											 NSString* title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Inbox (%d)", nil), n] : NSLocalizedString(@"Inbox", nil);
											 [sections addObject:@{@"title": title, @"rows": inbox}];
											 
											 for (NSDictionary* dictionary in @[corps, mailingLists]) {
												 NSArray* values = [[dictionary allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contact.name" ascending:YES]]];
												 for (NSDictionary* dic in values) {
													 NSInteger n = numberOfUnreadMessages(dic[@"messages"]);
													 NSString* title = n > 0 ? [NSString stringWithFormat:@"%@ (%d)", [dic[@"contact"] name], n] : [dic[@"contact"] name];
													 [sections addObject:@{@"title": title, @"rows": dic[@"messages"]}];
												 }
											 }
											 
											 n = numberOfUnreadMessages(sent);
											 title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Sent (%d)", nil), n] : NSLocalizedString(@"Sent", nil);
											 [sections addObject:@{@"title": title, @"rows": sent}];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

#pragma mark - Private

- (void) setMailBox:(NCMailBox *)mailBox {
	if (_mailBox)
		[_mailBox removeObserver:self forKeyPath:@"readedMessagesIDs"];
	_mailBox = mailBox;
	[_mailBox addObserver:self forKeyPath:@"readedMessagesIDs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

@end
