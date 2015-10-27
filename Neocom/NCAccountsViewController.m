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

@interface NCAccountsViewControllerDataAccount : NSObject<NSSecureCoding>
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, assign) int32_t characterID;
@property (nonatomic, strong) NCAPIKey* apiKey;
@property (nonatomic, strong) NSError* error;

@property (nonatomic, strong) NSString* uuid;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVEAccountBalance* accountBalance;
@property (nonatomic, strong) EVECharacterInfo* characterInfo;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVECorporationSheet* corporationSheet;
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, assign) NCAccountType accountType;
@property (nonatomic) int32_t keyID;
@property (nonatomic, strong) EVEAPIKeyInfo* apiKeyInfo;
@property (nonatomic, strong) NCSkillData* trainingSkill;
@property (nonatomic, strong) NSString* trainingSkillTypeName;
@end

@implementation NCAccountsViewControllerDataAccount

+ (BOOL) supportsSecureCoding {
	return YES;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.uuid = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"uuid"];
		self.characterID = [aDecoder decodeInt32ForKey:@"characterID"];
		self.accountStatus = [aDecoder decodeObjectOfClass:[EVEAccountStatus class] forKey:@"accountStatus"];
		self.accountBalance = [aDecoder decodeObjectOfClass:[EVEAccountBalance class] forKey:@"accountBalance"];
		self.characterInfo = [aDecoder decodeObjectOfClass:[EVECharacterInfo class] forKey:@"characterInfo"];
		self.characterSheet = [aDecoder decodeObjectOfClass:[EVECharacterSheet class] forKey:@"characterSheet"];
		self.corporationSheet = [aDecoder decodeObjectOfClass:[EVECorporationSheet class] forKey:@"corporationSheet"];
		self.skillQueue = [aDecoder decodeObjectOfClass:[EVESkillQueue class] forKey:@"skillQueue"];
		self.accountType = [aDecoder decodeIntegerForKey:@"accountType"];
		self.keyID = [aDecoder decodeInt32ForKey:@"keyID"];
		self.apiKeyInfo = [aDecoder decodeObjectOfClass:[EVEAPIKeyInfo class] forKey:@"apiKeyInfo"];
		self.trainingSkillTypeName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"trainingSkillTypeName"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.uuid forKey:@"uuid"];
	[aCoder encodeInt32:self.characterID forKey:@"characterID"];
	[aCoder encodeObject:self.accountStatus forKey:@"accountStatus"];
	[aCoder encodeObject:self.accountBalance forKey:@"accountBalance"];
	[aCoder encodeObject:self.characterInfo forKey:@"characterInfo"];
	[aCoder encodeObject:self.characterSheet forKey:@"characterSheet"];
	[aCoder encodeObject:self.corporationSheet forKey:@"corporationSheet"];
	[aCoder encodeObject:self.skillQueue forKey:@"skillQueue"];
	[aCoder encodeInteger:self.accountType forKey:@"accountType"];
	[aCoder encodeInt32:self.keyID forKey:@"keyID"];
	[aCoder encodeObject:self.apiKeyInfo forKey:@"apiKeyInfo"];
	[aCoder encodeObject:self.trainingSkillTypeName forKey:@"trainingSkillTypeName"];
}

- (NSString*) description {
	return [self.account description];
}

@end

@interface NCAccountsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* accounts;
@end



@implementation NCAccountsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
        self.accounts = [[aDecoder decodeObjectForKey:@"accounts"] mutableCopy];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    if (self.accounts)
        [aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end


@interface NCAccountsViewController ()
@property (nonatomic, assign) NSInteger mode;
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
//	self.storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.logoutItem.enabled = [NCAccount currentAccount] != nil;
	
	self.modeSetting = [self.storageManagedObjectContext settingWithKey:@"NCAccountsViewController.mode"];
	self.mode = [self.modeSetting.value integerValue];
	self.modeSegmentedControl.selectedSegmentIndex = self.mode;
	self.cacheRecordID = NSStringFromClass(self.class);
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
			NCAccountsViewControllerData* data = self.cacheData;
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
			NCAccountsViewControllerData* data = self.cacheData;
			NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
			controller.account = account.account;
		}
	}
}

- (IBAction)onChangeMode:(id)sender {
	[self.tableView reloadData];
	self.mode = self.modeSegmentedControl.selectedSegmentIndex;
	self.modeSetting.value = @(self.mode);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NCAccountsViewControllerData* data = self.cacheData;
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
		NCAccountsViewControllerData* data = self.cacheData;
		NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
		
		[tableView beginUpdates];
		if ([NCAccount currentAccount] == account.account) {
			[NCAccount setCurrentAccount:nil];
		}
		
		[[NCAccountsManager sharedManager] removeAccount:account.account];
		[data.accounts removeObjectAtIndex:indexPath.row];
		
		NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
		updatedData.accounts = data.accounts;
		[self saveCacheData:self.cacheData cacheDate:nil expireDate:nil];
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		[tableView endUpdates];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NCAccountsViewControllerData* data = self.cacheData;
	NCAccountsViewControllerDataAccount* account = data.accounts[fromIndexPath.row];
	[data.accounts removeObjectAtIndex:fromIndexPath.row];
	[data.accounts insertObject:account atIndex:toIndexPath.row];
	
	int32_t order = 0;
	for (NCAccountsViewControllerDataAccount* account in data.accounts)
		account.account.order = order++;

	NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		if ([storageManagedObjectContext hasChanges])
			[storageManagedObjectContext save:nil];
	}];

	NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
	updatedData.accounts = data.accounts;
	[self saveCacheData:self.cacheData cacheDate:nil expireDate:nil];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 102;
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock {
	NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
	if (!accountsManager) {
		completionBlock(nil);
		return;
	}
	NCAccountsViewControllerData* cacheData = self.cacheData;
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];

	NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
	[accountsManager loadAccountsWithCompletionBlock:^(NSArray *accounts, NSArray* apiKeys) {
		[storageManagedObjectContext performBlock:^{
			__block NSError* lastError;
			NCAccountsViewControllerData* data = [NCAccountsViewControllerData new];
			data.accounts = [NSMutableArray new];
			
			
			__block dispatch_group_t finishGroup = dispatch_group_create();
			[progress becomeCurrentWithPendingUnitCount:1];
			NSProgress* accountsTotalProgress = [NSProgress progressWithTotalUnitCount:accounts.count];
			[progress resignCurrent];
			
			
			for (NCAccount* account in accounts) {
				dispatch_group_enter(finishGroup);
				BOOL corporate = account.accountType == NCAccountTypeCorporate;
				
				NCAccountsViewControllerDataAccount* dataAccount = [[cacheData.accounts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", account.uuid]] lastObject] ?: [NCAccountsViewControllerDataAccount new];
				
				dataAccount.account = account;
				dataAccount.accountType = account.accountType;
				dataAccount.characterID = account.characterID;
				dataAccount.apiKey = account.apiKey;
				dataAccount.keyID = account.apiKey.keyID;
				dataAccount.uuid = account.uuid;
				dataAccount.apiKeyInfo = account.apiKey.apiKeyInfo;
				
				EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
				dispatch_group_t partialFinishDispatchGroup = dispatch_group_create();
				
				[accountsTotalProgress becomeCurrentWithPendingUnitCount:1];
				NSProgress* accountProgress = [NSProgress progressWithTotalUnitCount:4];
				[accountsTotalProgress resignCurrent];

				dispatch_group_enter(partialFinishDispatchGroup);
				[api accountStatusWithCompletionBlock:^(EVEAccountStatus *result, NSError *error) {
					dataAccount.accountStatus = result;
					dispatch_group_leave(partialFinishDispatchGroup);
					@synchronized(accountProgress) {
						accountProgress.completedUnitCount++;
					}
				} progressBlock:nil];
				
				if (corporate) {
					dispatch_group_enter(partialFinishDispatchGroup);
					[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *result, NSError *error) {
						dataAccount.accountBalance = result;
						dispatch_group_leave(partialFinishDispatchGroup);
						@synchronized(accountProgress) {
							accountProgress.completedUnitCount++;
						}
					} progressBlock:nil];
				}
				else
					@synchronized(accountProgress) {
						accountProgress.completedUnitCount++;
					}
				
				void (^reload)() = ^{
					dispatch_async(dispatch_get_main_queue(), ^{
						NCAccountsViewControllerData* data = self.cacheData;
						if (data) {
							[self saveCacheData:data cacheDate:nil expireDate:nil];
							NSInteger i = [data.accounts indexOfObject:dataAccount];
							if (i != NSNotFound)
								[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
						}
						dispatch_group_leave(finishGroup);
						@synchronized(accountProgress) {
							accountProgress.completedUnitCount++;
						}
					});
				};
				
				dispatch_group_notify(partialFinishDispatchGroup, dispatch_get_main_queue(), ^{
					[account reloadWithCachePolicy:cachePolicy completionBlock:^(NSError *error) {
						if (error)
							lastError = error;
						[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
							@synchronized(accountProgress) {
								accountProgress.completedUnitCount++;
							}
							dataAccount.error = error;
							dataAccount.characterInfo = characterInfo;
							if (corporate) {
								[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
									dataAccount.corporationSheet = corporationSheet;
									reload();
								}];
							}
							else {
								[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
									dataAccount.characterSheet = characterSheet;
									[account loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error) {
										dataAccount.skillQueue = skillQueue;
										reload();
									}];
								}];
							}
						}];
					} progressBlock:nil];
				});
				
				[data.accounts addObject:dataAccount];
			}
			
			dispatch_group_notify(finishGroup, dispatch_get_main_queue(), ^{
				completionBlock(lastError);
				finishGroup = nil;
			});

			dispatch_async(dispatch_get_main_queue(), ^{
				[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
				[self.tableView reloadData];
			});
		}];
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCAccountsViewControllerData* data = cacheData;
	NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		for (NCAccountsViewControllerDataAccount* account in data.accounts) {
			if (!account.account)
				account.account = [storageManagedObjectContext accountWithUUID:account.uuid];
			if (!account.apiKey)
				account.apiKey = [storageManagedObjectContext apiKeyWithKeyID:account.keyID];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			for (NCAccountsViewControllerDataAccount* account in data.accounts) {
				if (account.skillQueue.skillQueue.count > 0 && !account.trainingSkill) {
					EVESkillQueueItem* item = account.skillQueue.skillQueue[0];
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
					account.trainingSkill = [[NCSkillData alloc] initWithInvType:type];
					account.trainingSkillTypeName = type.typeName;
				}
			}
			completionBlock();
		});
	}];
}

- (void) didChangeStorage:(NSNotification*) notification {
	[super didChangeStorage:notification];
	[self invalidateCache];
	[self reload];
}

- (void) managedObjectContextDidFinishUpdate:(NSNotification *)notification {
	[super managedObjectContextDidFinishUpdate:notification];
	[notification.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, NSSet* set, BOOL *stop) {
		for (NSManagedObject* object in set)
			if ([object isKindOfClass:[NCAccount class]]) {
				*stop = YES;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self invalidateCache];
					[self reload];
				});
				break;
			}
	}];
}

/*- (BOOL) shouldReloadData {
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
}*/

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCAccountsViewControllerData* data = self.cacheData;
	NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
	
	BOOL detailed = self.modeSegmentedControl.selectedSegmentIndex == 0;
	
	if (!account.characterInfo) {
		EVEAPIKeyInfoCharactersItem* item = [[account.apiKeyInfo.key.characters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"characterID == %d", account.characterID]] lastObject];
		if (item) {
			if (account.accountType == NCAccountTypeCharacter) {
				NCAccountCharacterCell* cell = (NCAccountCharacterCell*) tableViewCell;
				cell.characterImageView.image = nil;
				cell.corporationImageView.image = nil;
				cell.allianceImageView.image = nil;
				
				cell.characterNameLabel.text = item.characterName;
				cell.corporationNameLabel.text = item.corporationName;
				cell.allianceNameLabel.text = item.allianceName;
				
				if (item.characterID)
					[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:item.characterID size:EVEImageSizeRetina64 error:nil]];
				if (item.corporationID)
					[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:item.corporationID size:EVEImageSizeRetina32 error:nil]];
				if (item.allianceID)
					[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:item.allianceID size:EVEImageSizeRetina32 error:nil]];
				cell.detailsLabel.text = account.error ? [account.error localizedDescription] : NSLocalizedString(@"Loading", nil);
			}
			else {
				NCAccountCorporationCell* cell = (NCAccountCorporationCell*) tableViewCell;
				cell.corporationImageView.image = nil;
				cell.allianceImageView.image = nil;
				
				cell.corporationNameLabel.text = item.corporationName;
				cell.allianceNameLabel.text = item.allianceName;
				
				if (item.corporationID)
					[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:item.corporationID size:EVEImageSizeRetina32 error:nil]];
				if (item.allianceID)
					[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:item.allianceID size:EVEImageSizeRetina32 error:nil]];
				cell.detailsLabel.text = account.error ? [account.error localizedDescription] : NSLocalizedString(@"Loading", nil);
			}
		}
		else {
			NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
			cell.titleLabel.text = account.error ? [account.error localizedDescription] : NSLocalizedString(@"Loading", nil);
		}
	}
	else {
		if (account.accountType == NCAccountTypeCharacter) {
			NSMutableAttributedString* s = [NSMutableAttributedString new];
			NCAccountCharacterCell *cell = (NCAccountCharacterCell*) tableViewCell;
			
			cell.characterImageView.image = nil;
			cell.corporationImageView.image = nil;
			cell.allianceImageView.image = nil;
			
			[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSizeRetina64 error:nil]];
			EVECharacterInfo* characterInfo = account.characterInfo;
			EVECharacterSheet* characterSheet = account.characterSheet;
			
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
			
			
			EVESkillQueue* sq = account.skillQueue;
			if (sq) {
				NSString *text;
				UIColor *color = nil;
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
						
						float sp = characterSheetSkill.skillPoints;
						float start = [account.trainingSkill skillPointsAtLevel:item.level - 1];
						float end = [account.trainingSkill skillPointsAtLevel:item.level];
						float progress = (sp - start) / (end - start);
						NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithString:[NSString stringWithFormat:@"%@ %d", account.trainingSkillTypeName, item.level] url:[NSURL URLWithString:[NSString stringWithFormat:@"showinfo:%d", item.typeID]]]];
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
				[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
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
				apiKeyMask = [NSAttributedString attributedStringWithString:[NSString stringWithFormat:NSLocalizedString(@"API Key %d. Tap to see Access Mask", nil), account.keyID]
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
			
			EVECorporationSheet* corporationSheet = account.corporationSheet;
			
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
				apiKeyMask = [NSAttributedString attributedStringWithString:[NSString stringWithFormat:NSLocalizedString(@"API Key %d. Tap to see Access Mask", nil), account.keyID]
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
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccountsViewControllerData* data = self.cacheData;
	NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
	if (!account.characterInfo) {
		EVEAPIKeyInfoCharactersItem* item = [[account.apiKeyInfo.key.characters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"characterID == %d", account.characterID]] lastObject];
		if (!item)
			return @"Cell";
	}
	
	if (account.accountType == NCAccountTypeCharacter)
		return @"NCAccountCharacterCell";
	else
		return @"NCAccountCorporationCell";
}

#pragma mark - Unwind

- (IBAction) unwindToAccounts:(UIStoryboardSegue*) segue {
//	if ([self shouldReloadData])
//		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

@end
