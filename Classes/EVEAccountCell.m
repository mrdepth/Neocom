//
//  EVEAccountCell.m
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import "EVEAccountCell.h"
#import "EVEAccount.h"
#import "UIImageView+URL.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+TimeLeft.h"
#import "appearance.h"

@implementation EVEAccountCell

- (void) awakeFromNib {
	self.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.layer.cornerRadius = 8;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)onDelete:(id)sender {
	[self.delegate accountCell:self deleteButtonTapped:sender];
}

- (IBAction)onFavorite:(id)sender {
	[self.delegate accountCell:self favoritesButtonTapped:sender];
}

- (IBAction)onCharKey:(id)sender {
	[self.delegate accountCell:self charKeyButtonTapped:sender];
}

- (IBAction)onCorpKey:(id)sender {
	[self.delegate accountCell:self corpKeyButtonTapped:sender];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	self.favoritesButton.alpha = editing ? 1.0 : 0.0;
	self.deleteButton.alpha = editing ? 1.0 : 0.0;
}

- (void) setAccount:(EVEAccount *)account {
	_account = account;
	
	//self.portraitImageView.image = [UIImage imageNamed:@"noAccount.png"];
	[self.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.character.characterID
																							   size:[[UIScreen mainScreen] scale] == 2.0 ? EVEImageSize128 : EVEImageSize64
																							  error:nil]];
	
	//self.corpImageView.image = nil;
	
	[self.corpImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:account.character.corporationID
																						   size:EVEImageSize32
																						  error:nil]];
	if (account.characterInfo.allianceID) {
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:account.characterInfo.allianceID
																							   size:EVEImageSize32
																							  error:nil]];
		self.allianceLabel.text = account.characterInfo.alliance;
	}
	else {
		self.allianceImageView.image = nil;
		self.allianceLabel.text = nil;
	}
	
	self.characterNameLabel.text = account.character.characterName;
	self.corpLabel.text = account.character.corporationName;
	if (account.accountBalance.accounts.count > 0) {
		EVEAccountBalanceItem* balance = account.accountBalance.accounts[0];
		self.wealthLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(balance.balance)]];
	}
	else
		self.wealthLabel.text = NSLocalizedString(@"Account balance not available", nil);
	
	self.locationLabel.text = account.characterInfo.lastKnownLocation;
	self.shipLabel.text = account.characterInfo.shipTypeName;
	
	NSString *text;
	UIColor *color = nil;
	if (account.skillQueue) {
		if (account.skillQueue.skillQueue.count > 0) {
			NSDate *endTime = [[account.skillQueue.skillQueue lastObject] endTime];
			NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[account.skillQueue serverTimeWithLocalTime:[NSDate date]]];
			if (timeLeft > 3600 * 24)
				color = [UIColor greenColor];
			else
				color = [UIColor yellowColor];
			text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], account.skillQueue.skillQueue.count];
		}
		else {
			text = NSLocalizedString(@"Training queue is inactive", nil);
			color = [UIColor redColor];
		}
	}
	else {
		text = NSLocalizedString(@"Can't request skill queue", nil);
		color = [UIColor redColor];
	}
	
	self.skillsLabel.text = text;
	self.skillsLabel.textColor = color;
	
	if (account.accountStatus) {
		UIColor *color;
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		int days = [account.accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
		if (days < 0)
			days = 0;
		if (days > 7)
			color = [UIColor greenColor];
		else if (days == 0)
			color = [UIColor redColor];
		else
			color = [UIColor yellowColor];
		self.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Paid until %@ (%d days remaining)", nil), [dateFormatter stringFromDate:account.accountStatus.paidUntil], days];
		self.subscriptionLabel.textColor = color;
	}
	else {
		self.subscriptionLabel.text = NSLocalizedString(@"Can't request subscription information", nil);
		self.subscriptionLabel.textColor = [UIColor lightGrayColor];
	}
	
	int charKeysCount = 0;
	int corpKeysCount = 0;
	for (APIKey* key in account.apiKeys)
		if (key.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
			corpKeysCount++;
		else
			charKeysCount++;
	
	if (charKeysCount == 0)
		[self.charKeyButton setTitle:NSLocalizedString(@"No char keys", nil) forState:UIControlStateNormal];
	else if (charKeysCount == 1)
		[self.charKeyButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Char key: %d", nil), account.charAPIKey.keyID] forState:UIControlStateNormal];
	else
		[self.charKeyButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d Char keys", nil), charKeysCount] forState:UIControlStateNormal];
	
	if (corpKeysCount == 0)
		[self.corpKeyButton setTitle:NSLocalizedString(@"No corp keys", nil) forState:UIControlStateNormal];
	else if (corpKeysCount == 1)
		[self.corpKeyButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Corp key: %d", nil), account.corpAPIKey.keyID] forState:UIControlStateNormal];
	else
		[self.corpKeyButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d corp keys", nil), corpKeysCount] forState:UIControlStateNormal];
	
	self.favoritesButton.selected = !account.ignored;

}

@end
