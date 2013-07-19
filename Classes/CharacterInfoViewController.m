//
//  CharacterInfoViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterInfoViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEAccount.h"
#import "Globals.h"
#import "EUOperationQueue.h"
#import "NSString+TimeLeft.h"
#import "UIImageView+URL.h"

@interface CharacterInfoViewController()
@property (nonatomic, strong) NSURL* portraitURL;
- (void) update;
@end

@implementation CharacterInfoViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[self setSelectCharacterLabel:nil];
    [super viewDidUnload];
	[self setContentView:nil];
	[self setCharacterNameLabel:nil];
	[self setCorpLabel:nil];
	[self setAllianceLabel:nil];
	[self setWealthLabel:nil];
	[self setSkillsLabel:nil];
	self.portraitImageView = nil;
	self.corpImageView = nil;
	self.allianceImageView = nil;
}


- (IBAction)onReloadPortrait:(id)sender {
	float scale = [[UIScreen mainScreen] scale];
	[self.portraitImageView setImageWithContentsOfURL:self.portraitURL scale:scale ignoreCacheData:YES completion:nil failureBlock:nil];
}

- (void) setAccount:(EVEAccount *)account {
	_account = account;
	if (account) {
		[self update];
	}
	else {
		[UIView animateWithDuration:0.5
							  delay:0
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 CGRect frame = self.contentView.frame;
							 frame.size.height = 0;
							 //self.contentView.frame = frame;
						 } completion:nil];
		self.portraitImageView.image = [UIImage imageNamed:@"noAccount.png"];
		self.characterNameLabel.text = nil;
		self.selectCharacterLabel.hidden = NO;
		self.corpImageView.image = nil;
		self.allianceImageView.image = nil;
		self.corpLabel.text = nil;
		self.allianceLabel.text = nil;
		self.wealthLabel.text = nil;
		self.skillsLabel.text = nil;
	}
}

#pragma mark - Private

- (void) update {
	float scale = [[UIScreen mainScreen] scale];
	__block NSURL *corpURL = nil;
	__block NSString* wealth = nil;
	__block NSInteger allianceID = 0;
	__block NSString *allianceName = nil;
	__block NSMutableString *skillsText = nil;

	EVEAccount* account = self.account;
	EUOperation *operation = [EUOperation operationWithIdentifier:@"CharacterInfoViewController+Update" name:NSLocalizedString(@"Loading Character Info", nil)];
	[operation addExecutionBlock:^(void) {
		if (scale == 2.0) {
			self.portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize128 error:nil];
			corpURL = [EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize64 error:nil];
		}
		else {
			self.portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil];
			corpURL = [EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize32 error:nil];
		}
		
		
		if (account.characterSheet) {
			allianceID = account.characterSheet.allianceID;
			allianceName = account.characterSheet.allianceName;
			wealth = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:account.characterSheet.balance] numberStyle:NSNumberFormatterDecimalStyle]];
		}
		else {
			wealth = @"";
			NSError *error = nil;
			EVECorporationSheet *corporationSheet = [EVECorporationSheet corporationSheetWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporationID:account.corporationID error:&error progressHandler:nil];
			if (!error) {
				allianceID = corporationSheet.allianceID;
				allianceName = corporationSheet.allianceName;
			}
		}
		
		int skillpoints = 0;
		for (EVECharacterSheetSkill *skill in account.characterSheet.skills)
			skillpoints += skill.skillpoints;
		if (account.skillQueue) {
			skillsText = [NSMutableString stringWithFormat:NSLocalizedString(@"%@ points (%d skills)\n", nil),
					[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skillpoints] numberStyle:NSNumberFormatterDecimalStyle],
					account.characterSheet.skills.count];
			
			if (account.skillQueue.skillQueue.count > 0) {
				NSDate *endTime = [[account.skillQueue.skillQueue lastObject] endTime];
				NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[account.skillQueue serverTimeWithLocalTime:[NSDate date]]];
				[skillsText appendFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], account.skillQueue.skillQueue.count];
				
			}
			else
				[skillsText appendString:NSLocalizedString(@"Training queue is inactive", nil)];
		}

	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		[self.portraitImageView setImageWithContentsOfURL:self.portraitURL scale:scale completion:nil failureBlock:nil];
		[self.corpImageView setImageWithContentsOfURL:corpURL scale:scale completion:nil failureBlock:nil];
		self.characterNameLabel.text = account.characterName;
		self.corpLabel.text = account.corporationName;
		self.wealthLabel.text = wealth;
		self.skillsLabel.text = skillsText;
		self.selectCharacterLabel.hidden = YES;
		
		if (allianceID) {
			NSURL *allianceUrl = nil;
			if (RETINA_DISPLAY)
				allianceUrl = [EVEImage allianceLogoURLWithAllianceID:allianceID size:EVEImageSize64 error:nil];
			else
				allianceUrl = [EVEImage allianceLogoURLWithAllianceID:allianceID size:EVEImageSize32 error:nil];
			
			[self.allianceImageView setImageWithContentsOfURL:allianceUrl scale:scale completion:nil failureBlock:nil];
			self.allianceLabel.text = allianceName;
		}
		else {
			self.allianceImageView.image = nil;
			self.allianceLabel.text = @"";
		}
	}];

	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end

