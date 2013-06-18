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
- (void) update;
- (void) updateCharacterInfo:(EVEAccount*) account;
- (void) updateSkillInfoWithAccount:(EVEAccount*) account;
- (void) show;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) checkServerStatus;
@end

@implementation CharacterInfoViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.delegate characterInfoViewController:self willChangeContentSize:CGSizeMake(320, 24) animated:NO];
	[self checkServerStatus];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self update];
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
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.portraitImageView = nil;
	self.corpImageView = nil;
	self.allianceImageView = nil;
	self.corpLabel = nil;
	self.allianceLabel = nil;
	self.skillsLabel = nil;
	self.wealthLabel = nil;
	self.serverStatusLabel = nil;
	self.onlineLabel = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Private

- (void) update {
	EVEAccount *account = [EVEAccount currentAccount];
	[self checkServerStatus];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"CharacterInfoViewController+Update+%p", self] name:NSLocalizedString(@"Loading Character Info", nil)];
	[operation addExecutionBlock:^(void) {
		[self updateCharacterInfo:account];
	}];

	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) updateCharacterInfo:(EVEAccount*) account {
	if (account) {
		NSURL *portraitURL;
		NSURL *corpURL;
		float scale;
		if (RETINA_DISPLAY) {
			portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize128 error:nil];
			corpURL = [EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize64 error:nil];
			scale = 2;
		}
		else {
			portraitURL = [EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil];
			corpURL = [EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize32 error:nil];
			scale = 1;
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.portraitImageView setImageWithContentsOfURL:portraitURL scale:scale completion:nil failureBlock:nil];
			[self.corpImageView setImageWithContentsOfURL:corpURL scale:scale completion:nil failureBlock:nil];
			self.corpLabel.text = account.corporationName;
		});

		NSInteger allianceID = 0;
		NSString *allianceName = nil;
		
		NSString* wealth = nil;
		
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

		dispatch_async(dispatch_get_main_queue(), ^{
			self.wealthLabel.text = wealth;
		});

		dispatch_async(dispatch_get_main_queue(), ^{
			if (allianceID) {
				NSURL *allianceUrl = nil;
				if (RETINA_DISPLAY)
					allianceUrl = [EVEImage allianceLogoURLWithAllianceID:allianceID size:EVEImageSize64 error:nil];
				else
					allianceUrl = [EVEImage allianceLogoURLWithAllianceID:allianceID size:EVEImageSize32 error:nil];
				
				//[self.allianceImageView setImageWithContentsOfURL:allianceUrl scale:scale];
				[self.allianceImageView setImageWithContentsOfURL:allianceUrl scale:scale completion:nil failureBlock:nil];
				self.allianceLabel.text = allianceName;
			}
			else {
				self.allianceImageView.image = nil;
				self.allianceLabel.text = @"";
			}
		});

		[self updateSkillInfoWithAccount:account];
		[self performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
	}
	else {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.corpLabel.text = NSLocalizedString(@"No Character Selected", nil);
		});
		if (self.view.frame.size.height != 24) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate characterInfoViewController:self willChangeContentSize:CGSizeMake(320, 24) animated:YES];
			});
		}
	}
}

- (void) updateSkillInfoWithAccount:(EVEAccount*) account {
	int skillpoints = 0;
	for (EVECharacterSheetSkill *skill in account.characterSheet.skills)
		skillpoints += skill.skillpoints;
	NSMutableString *text = nil;
	if (account.skillQueue) {
		text = [NSMutableString stringWithFormat:NSLocalizedString(@"%@ points (%d skills)\n", nil),
				[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skillpoints] numberStyle:NSNumberFormatterDecimalStyle],
				account.characterSheet.skills.count];

		if (account.skillQueue.skillQueue.count > 0) {
			NSDate *endTime = [[account.skillQueue.skillQueue lastObject] endTime];
			NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[account.skillQueue serverTimeWithLocalTime:[NSDate date]]];
			[text appendFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], account.skillQueue.skillQueue.count];
			
		}
		else
			[text appendString:NSLocalizedString(@"Training queue is inactive", nil)];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.skillsLabel.text = text;
	});
}

- (void) show {
	if (self.view.frame.size.height != 142)
		[self.delegate characterInfoViewController:self willChangeContentSize:CGSizeMake(320, 142) animated:YES];
}

- (void) didSelectAccount:(NSNotification*) notification {
	[self update];
}

- (void) checkServerStatus {
	NSOperationQueue* queue = [[NSOperationQueue alloc] init];
	
	[queue addOperationWithBlock:^{
		@autoreleasepool {
			NSError* error = nil;
			EVEServerStatus *serverStatus = [EVEServerStatus serverStatusWithError:&error progressHandler:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				if (error) {
					self.serverStatusLabel.text = NSLocalizedString(@"Error", nil);
					self.onlineLabel.text = @"";
				}
				else {
					self.serverStatusLabel.text = serverStatus.serverOpen ? NSLocalizedString(@"Online", nil) : NSLocalizedString(@"Offline", nil);
					self.onlineLabel.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:serverStatus.onlinePlayers] numberStyle:NSNumberFormatterDecimalStyle];
					
					NSDate* cachedUntil = [serverStatus localTimeWithServerTime:serverStatus.cachedUntil];
					NSTimeInterval timeInterval = [cachedUntil timeIntervalSinceNow];
					if (timeInterval < 30 * 60)
						timeInterval = 30 * 60;
					
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkServerStatus) object:nil];
					[self performSelector:@selector(checkServerStatus) withObject:nil afterDelay:timeInterval];
				}
			});
		}
	}];
}

@end
