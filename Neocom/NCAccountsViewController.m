//
//  NCAccountsViewController.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccountsViewController.h"
#import "NCAccountsManager.h"
#import "NCStorage.h"
#import "NCAccountCharacterCell.h"
#import "NCAccountCorporationCell.h"
#import "UIImageView+URL.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCAPIKeyAccessMaskViewController.h"
#import "NCStoryboardPopoverSegue.h"
#import "NCSetting.h"
#import "NSAttributedString+Neocom.h"
#import "UIColor+Neocom.h"

@interface NCAccountsViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVEAccountBalance* accountBalance;
@property (nonatomic, strong) NSString* currentSkill;
@end

@implementation NCAccountsViewControllerDataAccount

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NSString* udid = [aDecoder decodeObjectForKey:@"account"];
		if (udid) {
			self.account = [[NCStorage sharedStorage] accountWithUUID:udid];
			if (!self.account)
				return nil;
			
			self.accountStatus = [aDecoder decodeObjectForKey:@"accountStatus"];
			if (![self.accountStatus isKindOfClass:[EVEAccountStatus class]])
				self.accountStatus = nil;
			
			self.accountBalance = [aDecoder decodeObjectForKey:@"accountBalance"];
			if (![self.accountBalance isKindOfClass:[EVEAccountBalance class]])
				self.accountBalance = nil;
			
			self.currentSkill = [aDecoder decodeObjectForKey:@"currentSkill"];
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.account)
		[aCoder encodeObject:self.account.uuid forKey:@"account"];
	if (self.accountStatus)
		[aCoder encodeObject:self.accountStatus forKey:@"accountStatus"];
	if (self.accountBalance)
		[aCoder encodeObject:self.accountBalance forKey:@"accountBalance"];
	if (self.currentSkill)
		[aCoder encodeObject:self.currentSkill forKey:@"currentSkill"];
}

- (NSString*) description {
	return [self.account description];
}

@end

@interface NCAccountsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* apiKeys;
@end



@implementation NCAccountsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
        self.accounts = [[aDecoder decodeObjectForKey:@"accounts"] mutableCopy];
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;

        [context performBlockAndWait:^{
            self.apiKeys = [NSMutableArray arrayWithArray:[[NCStorage sharedStorage] allAPIKeys]];
        }];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    if (self.accounts)
        [aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end


@interface NCAccountsViewController ()
@property (nonatomic, strong) NCSetting* modeSetting;
@end

@implementation NCAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[[NCAccountsManager sharedManager] reload];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.logoutItem.enabled = [NCAccount currentAccount] != nil;
	self.modeSetting = [[NCStorage sharedStorage] settingWithKey:@"NCAccountsViewController.mode"];
	self.modeSegmentedControl.selectedSegmentIndex = [self.modeSetting.value boolValue] ? 1 : 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isKindOfClass:[NCStoryboardPopoverSegue class]])
		[(NCStoryboardPopoverSegue*) segue setAnchorView:sender];
	
	if (segue.identifier) {
		if ([segue.identifier isEqualToString:@"NCSelectCharAccount"] || [segue.identifier isEqualToString:@"NCSelectCorpAccount"]) {
			NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
			NCAccountsViewControllerData* data = self.data;
			NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
			[NCAccount setCurrentAccount:account.account];
		}
		else if ([segue.identifier isEqualToString:@"Logout"]) {
			[NCAccount setCurrentAccount:nil];
		}
		else if ([segue.identifier isEqualToString:@"NCCharAccessMask"] || [segue.identifier isEqualToString:@"NCCorpAccessMask"]) {
			NCAPIKeyAccessMaskViewController* controller = [segue.destinationViewController viewControllers][0];
			id cell = [sender superview];
			for (;![cell isKindOfClass:[UITableViewCell class]]; cell = [cell superview]);
			NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
			NCAccountsViewControllerData* data = self.data;
			NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
			controller.account = account.account;
		}
	}
}

- (IBAction)onChangeMode:(id)sender {
	self.modeSetting.value = @(self.modeSegmentedControl.selectedSegmentIndex == 1);
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NCAccountsViewControllerData* data = self.data;
	return data.accounts.count;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCAccountsViewControllerData* data = self.data;
		NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
		
		[tableView beginUpdates];
//		if ([NCAccount currentAccount] == account.account) {
//			[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//		}
		if ([NCAccount currentAccount] == account.account) {
			[NCAccount setCurrentAccount:nil];
		}
		
		[[NCAccountsManager sharedManager] removeAccount:account.account];
		[data.accounts removeObjectAtIndex:indexPath.row];
		
		NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
		updatedData.accounts = data.accounts;
		updatedData.apiKeys = data.apiKeys;
		[self didUpdateData:updatedData];
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		[tableView endUpdates];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NCAccountsViewControllerData* data = self.data;
	NCAccountsViewControllerDataAccount* account = data.accounts[fromIndexPath.row];
	[data.accounts removeObjectAtIndex:fromIndexPath.row];
	[data.accounts insertObject:account atIndex:toIndexPath.row];
	
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
	
	[context performBlockAndWait:^{
		int32_t order = 0;
		for (NCAccountsViewControllerDataAccount* account in data.accounts)
			account.account.order = order++;
		
		[storage saveContext];
	}];

	NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
	updatedData.accounts = data.accounts;
	updatedData.apiKeys = data.apiKeys;
	[self didUpdateData:updatedData];
	
	[[NCAccountsManager sharedManager] reload];
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 102;
}

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return NSStringFromClass(self.class);
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccountsViewControllerData* data = [NCAccountsViewControllerData new];
    data.accounts = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
											 if (!accountsManager)
												 return;
											 
											 float p = 0;
											 float dp = 1.0 / (accountsManager.accounts.count + accountsManager.apiKeys.count);
											 NSMutableDictionary* accountStatuses = [NSMutableDictionary new];
											 
											 for (NCAPIKey* apiKey in accountsManager.apiKeys) {
												 if (task.isCancelled)
													 return;

												 NSError* error = nil;
												 EVEAccountStatus* accountStatus = [EVEAccountStatus accountStatusWithKeyID:apiKey.keyID vCode:apiKey.vCode cachePolicy:cachePolicy error:&error progressHandler:nil];
												 if (accountStatus)
													 accountStatuses[@([apiKey hash])] = accountStatus;
												 task.progress = p += dp;
											 }
											 
											 for (NCAccount* account in accountsManager.accounts) {
												 if (task.isCancelled)
													 return;
												 
												 [account reloadWithCachePolicy:cachePolicy error:&error progressHandler:^(CGFloat progress, BOOL *stop) {
													 if (task.isCancelled)
														 *stop = YES;
												 }];
												 
												 if (task.isCancelled)
													 return;
												 
                                                 NCAccountsViewControllerDataAccount* dataAccount = [NCAccountsViewControllerDataAccount new];
                                                 dataAccount.account = account;
                                                 dataAccount.accountStatus = accountStatuses[@([account.apiKey hash])];
												 BOOL corporate = account.accountType == NCAccountTypeCorporate;
												 if (corporate)
													 dataAccount.accountBalance = [EVEAccountBalance accountBalanceWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID corporate:corporate error:nil progressHandler:nil];
                                                 [data.accounts addObject:dataAccount];
												 task.progress = p += dp;
												 
												 if (account.skillQueue.skillQueue.count > 0) {
													 EVESkillQueueItem* item = account.skillQueue.skillQueue[0];
													 NCDBInvType* type = [NCDBInvType invTypeWithTypeID:item.typeID];
													 dataAccount.currentSkill = [NSString stringWithFormat:NSLocalizedString(@"> %@ Level %d", nil), type.typeName, item.level];
												 }
											 }
											 NCStorage* storage = accountsManager.storage;
											 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;

                                             [context performBlockAndWait:^{
                                                 data.apiKeys = [[NSMutableArray alloc] initWithArray:[accountsManager.storage allAPIKeys]];
                                             }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
//									 if (error) {
//										 [self didFailLoadDataWithError:error];
//									 }
//									 else {
                                         [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
//									 }
								 }
							 }];
}

- (BOOL) shouldReloadData {
	BOOL shouldReloadData = [super shouldReloadData];
	if (!shouldReloadData) {
		for (NCAccount* account in [[NCAccountsManager sharedManager] accounts]) {
			BOOL exist = NO;
			for (NCAccountsViewControllerDataAccount* accountData in [self.cacheRecord.data.data accounts]) {
				if ([accountData.account isEqual:account]) {
					exist = YES;
					break;
				}
			}
			if (!exist) {
				shouldReloadData = YES;
				break;
			}
			if (account.accountType == NCAccountTypeCorporate) {
				if (!account.corporationSheet) {
					shouldReloadData = YES;
					break;
				}
			}
			else {
				if (!account.characterInfo) {
					shouldReloadData = YES;
					break;
				}
			}

		}
	}
	for (NCAccountsViewControllerDataAccount* accountData in [self.cacheRecord.data.data accounts]) {
		if (accountData.account.managedObjectContext == nil) {
			shouldReloadData = YES;
			break;
		}
	}
	return shouldReloadData;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCAccountsViewControllerData* data = self.data;
	NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
	
	BOOL detailed = ![self.modeSetting.value boolValue];

	
	if (account.account.accountType == NCAccountTypeCharacter) {
		NSMutableAttributedString* s = [NSMutableAttributedString new];
		NCAccountCharacterCell *cell = (NCAccountCharacterCell*) tableViewCell;
		
		cell.characterImageView.image = nil;
		cell.corporationImageView.image = nil;
		cell.allianceImageView.image = nil;
		
		[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.account.characterID size:EVEImageSizeRetina64 error:nil]];
		EVECharacterInfo* characterInfo = account.account.characterInfo;
		EVECharacterSheet* characterSheet = account.account.characterSheet;
		
		NSAttributedString* lastKnownLocation;
		NSAttributedString* skills;
		NSAttributedString* balance;
		NSAttributedString* skillQueue;
		NSAttributedString* subscription;
		NSAttributedString* currentSkill;
		NSAttributedString* apiKeyMask;

		if (detailed && characterInfo.lastKnownLocation && characterInfo.shipTypeName) {
			NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[characterInfo.lastKnownLocation stringByAppendingString:@", "] attributes:nil];
			[s appendAttributedString:[NSAttributedString attributedStringWithString:characterInfo.shipTypeName
																				 url:[NSURL URLWithString:[NSString stringWithFormat:@"showinfo:%d", characterInfo.shipTypeID]]]];
			lastKnownLocation = s;
		}

		if (characterInfo) {
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:characterInfo.corporationID size:EVEImageSizeRetina32 error:nil]];
			if (characterInfo.allianceID)
				[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:characterInfo.allianceID size:EVEImageSizeRetina32 error:nil]];
			
			if (detailed) {
				NSMutableAttributedString* sp = [[NSMutableAttributedString alloc] initWithString:[NSString shortStringWithFloat:characterInfo.skillPoints unit:nil]
																					   attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
				[sp appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" SP", nil) attributes:nil]];
				
				if (characterSheet) {
					[sp appendAttributedString:[[NSAttributedString alloc] initWithString:@" (" attributes:nil]];
					[sp appendAttributedString:[[NSAttributedString alloc] initWithString:[NSNumberFormatter neocomLocalizedStringFromNumber:@(characterSheet.skills.count)]
																			   attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}]];
					[sp appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" skills)", nil) attributes:nil]];
				}
				skills = sp;
			}
		}
		
		if (detailed)
			balance = [NSAttributedString shortAttributedStringWithFloat:characterSheet.balance unit:NSLocalizedString(@"ISK", nil)];
		
		cell.characterNameLabel.text = characterInfo.characterName ? characterInfo.characterName : NSLocalizedString(@"Unknown Error", nil);
		cell.corporationNameLabel.text = characterInfo.corporation;
		cell.allianceNameLabel.text = characterInfo.alliance;
		
		
		if (account.account.skillQueue) {
			NSString *text;
			UIColor *color = nil;
			EVESkillQueue* sq = account.account.skillQueue;
			if (sq.skillQueue.count > 0) {
				NSTimeInterval timeLeft = [sq timeLeft];
				if (timeLeft > 3600 * 24)
					color = [UIColor greenColor];
				else
					color = [UIColor yellowColor];
				text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], sq.skillQueue.count];
				
				if (detailed) {
					EVESkillQueueItem* item = sq.skillQueue[0];
					EVECharacterSheetSkill* characterSheetSkill = characterSheet.skillsMap[@(item.typeID)];

					NCSkillData* skillData = [[NCSkillData alloc] initWithTypeID:item.typeID];
					float sp = characterSheetSkill.skillpoints;
					float start = [skillData skillPointsAtLevel:item.level - 1];
					float end = [skillData skillPointsAtLevel:item.level];
					float progress = (sp - start) / (end - start);
					NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithString:[NSString stringWithFormat:@"%@ %d", skillData.type.typeName, item.level] url:[NSURL URLWithString:[NSString stringWithFormat:@"showinfo:%d", item.typeID]]]];
					[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%.0f%%)", progress * 100] attributes:nil]];
					currentSkill = s;
				}
			}
			else {
				text = NSLocalizedString(@"Training queue is inactive", nil);
				color = [UIColor redColor];
			}
			skillQueue = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:color}];
		}
		
		
		if (detailed && account.accountStatus) {
			UIColor *color;
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
			[dateFormatter setDateFormat:@"yyyy.MM.dd"];
			int days = [account.accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
			if (days < 0)
				days = 0;
			if (days > 7)
				color = [UIColor greenColor];
			else if (days == 0)
				color = [UIColor redColor];
			else
				color = [UIColor yellowColor];
			subscription = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Paid until %@ (%d days remaining)", nil), [dateFormatter stringFromDate:account.accountStatus.paidUntil], days]
														   attributes:@{NSForegroundColorAttributeName:color}];
		}
		
		if (detailed)
			apiKeyMask = [NSAttributedString attributedStringWithString:[NSString stringWithFormat:NSLocalizedString(@"API Key %d. Tap to see Access Mask", nil), account.account.apiKey.keyID]
																	url:[NSURL URLWithString:[NSString stringWithFormat:@"showinfo:%@", account.account.objectID.URIRepresentation.absoluteString]]];
		
		NSAttributedString* crlf = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
		if (lastKnownLocation) {
			[s appendAttributedString:lastKnownLocation];
			[s appendAttributedString:crlf];
		}
		if (skills) {
			[s appendAttributedString:skills];
			if (balance) {
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:@", " attributes:nil]];
				[s appendAttributedString:balance];
			}
			[s appendAttributedString:crlf];
		}
		else if (balance) {
			[s appendAttributedString:balance];
			[s appendAttributedString:crlf];
		}
		if (currentSkill) {
			[s appendAttributedString:currentSkill];
			[s appendAttributedString:crlf];
		}
		if (skillQueue) {
			[s appendAttributedString:skillQueue];
			[s appendAttributedString:crlf];
		}
		if (subscription) {
			[s appendAttributedString:subscription];
			[s appendAttributedString:crlf];
		}
		if (apiKeyMask)
			[s appendAttributedString:apiKeyMask];
		if ([s.string characterAtIndex:s.string.length - 1] == '\n')
			[s deleteCharactersInRange:NSMakeRange(s.string.length - 1, 1)];
		cell.detailsLabel.attributedText = s;
	}
	else {
		NCAccountCorporationCell *cell = (NCAccountCorporationCell*) tableViewCell;
		
		cell.corporationImageView.image = nil;
		cell.allianceImageView.image = nil;
		
		EVECorporationSheet* corporationSheet = account.account.corporationSheet;
		
		if (corporationSheet) {
			cell.corporationNameLabel.text = [NSString stringWithFormat:@"%@ [%@]", corporationSheet.corporationName, corporationSheet.ticker];
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:corporationSheet.corporationID size:EVEImageSizeRetina128 error:nil]];
			if (corporationSheet.allianceID)
				[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:corporationSheet.allianceID size:EVEImageSizeRetina32 error:nil]];
		}
		else
			cell.corporationNameLabel.text = NSLocalizedString(@"Unknown Error", nil);
		
		
		cell.allianceNameLabel.text = corporationSheet.allianceName;
		
		NSAttributedString* ceo;
		NSAttributedString* members;
		NSAttributedString* balance;
		NSAttributedString* apiKeyMask;
		
		if (detailed)
			ceo = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"CEO: %@", nil), corporationSheet.ceoName] attributes:nil];

		if (detailed) {
			NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ / %@ ",
																							  [NSNumberFormatter neocomLocalizedStringFromInteger:corporationSheet.memberCount],
																							  [NSNumberFormatter neocomLocalizedStringFromInteger:corporationSheet.memberLimit]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"members", nil) attributes:nil]];
			members = s;
		}
		
		if (detailed && account.accountBalance) {
			float sum = 0.0;
			for (EVEAccountBalanceItem* item in account.accountBalance.accounts)
				sum += item.balance;
			
			balance = [NSAttributedString shortAttributedStringWithFloat:sum unit:NSLocalizedString(@"ISK", nil)];
		}
		
		if (detailed)
			apiKeyMask = [NSAttributedString attributedStringWithString:[NSString stringWithFormat:NSLocalizedString(@"API Key %d. Tap to see Access Mask", nil), account.account.apiKey.keyID]
																	url:[NSURL URLWithString:[NSString stringWithFormat:@"showinfo:%@", account.account.objectID.URIRepresentation.absoluteString]]];
		NSAttributedString* crlf = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
		
		NSMutableAttributedString* s = [NSMutableAttributedString new];
		if (ceo) {
			[s appendAttributedString:ceo];
			[s appendAttributedString:crlf];
		}
		if (members) {
			[s appendAttributedString:members];
			if (balance) {
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:@", " attributes:nil]];
				[s appendAttributedString:balance];
			}
			[s appendAttributedString:crlf];
		}
		else if (balance) {
			[s appendAttributedString:balance];
			[s appendAttributedString:crlf];
		}
		if (apiKeyMask)
			[s appendAttributedString:apiKeyMask];
		if (s.length > 0) {
			if ([s.string characterAtIndex:s.string.length - 1] == '\n')
				[s deleteCharactersInRange:NSMakeRange(s.string.length - 1, 1)];
		}
		cell.detailsLabel.attributedText = s;
	}
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccountsViewControllerData* data = self.data;
	NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
	
	if (account.account.accountType == NCAccountTypeCharacter)
		return @"NCAccountCharacterCell";
	else
		return @"NCAccountCorporationCell";
}

#pragma mark - Unwind

- (IBAction) unwindToAccounts:(UIStoryboardSegue*) segue {
	if ([self shouldReloadData])
		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

@end
