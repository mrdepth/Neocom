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

@interface NCMailBoxViewController ()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NCMailBox* mailBox;
@property (nonatomic, assign) int32_t characterID;
@property (nonatomic, strong) NSArray* sections;

- (void) mailBoxDidUpdateNotification:(NSNotification*) notification;
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
	self.account = nil;
	self.mailBox = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCMailBoxMessageViewController"]) {
		NCMailBoxMessageViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.mailBox = self.mailBox;
		controller.message = [(NCMessageCell*) sender message];
	}
}

- (IBAction)markAsRead:(id)sender {
	NSArray* data = self.cacheData;
	[self.mailBox markAsRead:data];
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


#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
	[account.managedObjectContext performBlock:^{
		[progress becomeCurrentWithPendingUnitCount:1];
		[account.mailBox reloadWithCachePolicy:cachePolicy completionBlock:^(NSArray *messages, NSError *error) {
			lastError = error;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self saveCacheData:messages cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
				completionBlock(error);
			});
		} progressBlock:nil];
		[progress resignCurrent];
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NSArray* data = cacheData;
	int32_t myID = self.characterID;
	
	[self.account.managedObjectContext performBlock:^{

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			@autoreleasepool {
				NSMutableArray* sections = [NSMutableArray new];
				NSMutableArray* sent = [NSMutableArray new];
				NSMutableArray* inbox = [NSMutableArray new];
				NSMutableDictionary* corps = [NSMutableDictionary new];
				NSMutableDictionary* mailingLists = [NSMutableDictionary new];
				
				for (NCMailBoxMessage* message in data) {
					BOOL inInbox = NO;
					
					if (message.sender.contactID == myID)
						[sent addObject:message];
					else {
						for (NCMailBoxContact* contact in message.recipients) {
							if (contact.type == NCMailBoxContactTypeCharacter && contact.contactID == myID)
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
				NSString* title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Inbox (%d)", nil), (int32_t) n] : NSLocalizedString(@"Inbox", nil);
				[sections addObject:@{@"title": title, @"rows": inbox, @"sectionID": @(0)}];
				
				for (NSDictionary* dictionary in @[corps, mailingLists]) {
					NSArray* values = [[dictionary allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contact.name" ascending:YES]]];
					for (NSDictionary* dic in values) {
						NSInteger n = numberOfUnreadMessages(dic[@"messages"]);
						NCMailBoxContact* contact = dic[@"contact"];
						NSString* name = [dic[@"contact"] name];
						if (!name)
							name = NSLocalizedString(@"Unknown Contact", nil);
						NSString* title = n > 0 ? [NSString stringWithFormat:@"%@ (%d)", name, (int32_t)n] : name;
						[sections addObject:@{@"title": title, @"rows": dic[@"messages"], @"sectionID": @(contact.contactID)}];
					}
				}
				
				n = numberOfUnreadMessages(sent);
				title = n > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Sent (%d)", nil), (int32_t) n] : NSLocalizedString(@"Sent", nil);
				[sections addObject:@{@"title": title, @"rows": sent, @"sectionID": @(1)}];
				dispatch_async(dispatch_get_main_queue(), ^{
					self.sections = sections;
					self.backgrountText = sections.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
					completionBlock();
				});
			}
		});
	}];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (id) identifierForSection:(NSInteger)section {
	return self.sections[section][@"sectionID"];
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCMailBoxMessage* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NCMessageCell* cell = (NCMessageCell*) tableViewCell;
	cell.subjectLabel.text = row.header.title;
	BOOL isRead = [row isRead];
	cell.subjectLabel.font = isRead ? [UIFont systemFontOfSize:cell.subjectLabel.font.pointSize] : [UIFont boldSystemFontOfSize:cell.subjectLabel.font.pointSize];
	cell.subjectLabel.textColor = isRead ? [UIColor lightTextColor] : [UIColor whiteColor];
	cell.dateLabel.text = [row.header.sentDate messageTimeLocalizedString];
	
	NSInteger myID = self.characterID;
	
	if (row.sender.contactID == myID) {
		NSArray* recipients = [row.recipients valueForKey:@"name"];
		NSString* recipient = [recipients componentsJoinedByString:@", "];
		cell.senderLabel.text = [NSString stringWithFormat:NSLocalizedString(@"to %@", nil), recipient.length > 0 ? recipient : NSLocalizedString(@"Unknown", nil)];
	}
	else
		cell.senderLabel.text = [NSString stringWithFormat:NSLocalizedString(@"from %@", nil), row.sender.name.length > 0 ? row.sender.name : NSLocalizedString(@"Unknown", nil)];
	cell.message = row;
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		NCMailBox* mailBox = account.mailBox;
		int32_t characterID = account.characterID;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.characterID = characterID;
			self.mailBox = mailBox;
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

- (void) setMailBox:(NCMailBox *)mailBox {
	if (_mailBox)
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NCMailBoxDidUpdateNotification object:_mailBox];
	_mailBox = mailBox;
	if (_mailBox)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mailBoxDidUpdateNotification:) name:NCMailBoxDidUpdateNotification object:_mailBox];
}

- (void) mailBoxDidUpdateNotification:(NSNotification*) notification {
	[self.mailBox loadMessagesWithCompletionBlock:^(NSArray *messages, NSError *error) {
		if (messages) {
			[self saveCacheData:messages cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
			[self reload];
		}
	} progressBlock:nil];
}

@end
