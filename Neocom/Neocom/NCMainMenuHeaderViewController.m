//
//  NCMainMenuHeaderViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuHeaderViewController.h"
#import "NCAccount.h"
#import "NCDataManager.h"

@interface NCMainMenuHeaderViewController ()

@end

@implementation NCMainMenuHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	NCAccount* account = NCAccount.currentAccount;
	self.characterNameLabel.text = @" ";
	self.corporationLabel.text = @" ";
	self.allianceLabel.text = @" ";
	self.characterImageView.image = nil;
	self.corporationImageView.image = nil;
	self.allianceImageView.image = nil;
	
	self.corporationLabel.superview.hidden = YES;
	self.allianceLabel.superview.hidden = YES;
	
	NCDataManager* dataManager = [NCDataManager defaultManager];
	if (account.eveAPIKey.corporate) {

	}
	else {
		[dataManager characterInfoForAccount:account cachePolicy:NSURLRequestUseProtocolCachePolicy completionHandler:^(EVECharacterInfo *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			if (error) {
			}
			else {
				self.characterNameLabel.text = result.characterName;
				self.corporationLabel.text = result.corporation;
				self.allianceLabel.text = result.alliance;
				self.corporationLabel.superview.hidden = result.corporationID == 0;
				self.allianceLabel.superview.hidden = result.allianceID == 0;

				if (self.characterImageView)
					[dataManager imageWithCharacterID:result.characterID preferredSize:CGSizeMake(128, 128) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error) {
						self.characterImageView.image = image;
					}];
				if (self.corporationImageView && result.corporationID)
					[dataManager imageWithCorporationID:result.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error) {
						self.corporationImageView.image = image;
					}];
				if (self.allianceImageView && result.allianceID)
					[dataManager imageWithAllianceID:result.allianceID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error) {
						self.allianceImageView.image = image;
					}];
			}
		}];
	}
	
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCAccountsViewController"]) {
		segue.destinationViewController.transitioningDelegate = (id) self.parentViewController;
	}
	[super prepareForSegue:segue sender:sender];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onLogout:(id)sender {
	NCAccount.currentAccount = nil;
}

@end
