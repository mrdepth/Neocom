//
//  NCAssetsAccountsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 02.05.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAssetsAccountsViewController.h"
#import "NCAccountsManager.h"
#import "NCAccountCharacterCell.h"
#import "NCAccountCorporationCell.h"
#import "UIImageView+URL.h"

@interface NCAssetsAccountsViewController ()
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, assign, getter = isModified) BOOL modified;
@end

@implementation NCAssetsAccountsViewController

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
	self.accounts = [[NCAccountsManager sharedManager] accounts];
	self.modified = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.modified)
		[self.delegate assetsAccountsViewController:self didSelectAccounts:self.selectedAccounts];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.accounts.count;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NCAccount* account = self.accounts[indexPath.row];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	if ([self.selectedAccounts containsObject:account]) {
		if (self.selectedAccounts.count > 1) {
			NSMutableArray* selectedAccounts = [self.selectedAccounts mutableCopy];
			[selectedAccounts removeObject:account];
			self.selectedAccounts = selectedAccounts;
			cell.accessoryView = nil;
			self.modified = YES;
		}
	}
	else {
		NSMutableArray* selectedAccounts = self.selectedAccounts ? [self.selectedAccounts mutableCopy] : [NSMutableArray new];
		NSMutableIndexSet* indexes = [NSMutableIndexSet new];
		
		NSInteger i = 0;
		for (NCAccount* selectedAccount in selectedAccounts) {
			NSInteger j = [self.accounts indexOfObject:selectedAccount];
			if (selectedAccount.accountType == account.accountType && selectedAccount.characterID == account.characterID) {
				if (j != NSNotFound) {
					UITableViewCell* cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:0]];
					cell.accessoryView = nil;
				}
				[indexes addIndex:i];
			}
			i++;
		}
		
		if (indexes.count > 0)
			[selectedAccounts removeObjectsAtIndexes:indexes];
		
		[selectedAccounts addObject:account];
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
		self.selectedAccounts = selectedAccounts;
		self.modified = YES;
	}
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccount* account = self.accounts[indexPath.row];
	if (account.accountType == NCAccountTypeCharacter)
		return @"NCAccountCharacterCell";

	else
		return @"NCAccountCorporationCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAccount* account = self.accounts[indexPath.row];
	if (account.accountType == NCAccountTypeCharacter) {
		NCAccountCharacterCell *cell = (NCAccountCharacterCell*) tableViewCell;
		
		cell.characterImageView.image = nil;
		cell.corporationImageView.image = nil;
		cell.allianceImageView.image = nil;
		
		[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSizeRetina64 error:nil]];
		EVECharacterInfo* characterInfo = account.characterInfo;
		
		if (characterInfo) {
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:characterInfo.corporationID size:EVEImageSizeRetina32 error:nil]];
			if (characterInfo.allianceID)
				[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:characterInfo.allianceID size:EVEImageSizeRetina32 error:nil]];
		}
		
		cell.characterNameLabel.text = characterInfo.characterName ? characterInfo.characterName : NSLocalizedString(@"Unknown Error", nil);
		cell.corporationNameLabel.text = characterInfo.corporation;
		cell.allianceNameLabel.text = characterInfo.alliance;
		
		cell.accessoryView = [self.selectedAccounts containsObject:account] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
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
		
		cell.accessoryView = [self.selectedAccounts containsObject:account] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
}

@end
