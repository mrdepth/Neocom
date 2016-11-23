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
#import "NCLabel.h"

@interface NCMainMenuHeaderLabel : NCLabel
@end

@implementation NCMainMenuHeaderLabel

- (void) drawRect:(CGRect)rect {
	NSStringDrawingContext* context = [NSStringDrawingContext new];
	context.minimumScaleFactor = self.minimumScaleFactor;
	NSMutableAttributedString* s = [self.attributedText mutableCopy];
	NSMutableParagraphStyle* paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.maximumLineHeight = self.bounds.size.height;
	
	[s addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, s.length)];
	//[s drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:context];
	
	NSTextStorage* storage = [[NSTextStorage alloc] initWithAttributedString:s];
	NSLayoutManager* manager = [[NSLayoutManager alloc] init];
	NSTextContainer* container = [[NSTextContainer alloc] initWithSize:rect.size];
	[manager addTextContainer:container];
	[manager setTextStorage:storage];
	[manager drawGlyphsForGlyphRange:[manager glyphRangeForTextContainer:container] atPoint:rect.origin];
}

@end

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
	
	EVEAPIKeyInfoCharactersItem* character = account.character;

	self.characterNameLabel.text = character.characterName ?: @" ";
	self.corporationLabel.text = character.corporationName ?: @"";
	self.allianceLabel.text = character.allianceName ?: @"";
	self.corporationLabel.superview.hidden = character.corporationID == 0;
	self.allianceLabel.superview.hidden = character.allianceID == 0;

	NCDataManager* dataManager = [NCDataManager defaultManager];
	if (account.eveAPIKey.corporate) {
		if (self.corporationImageView && character.corporationID)
			[dataManager imageWithCorporationID:character.corporationID preferredSize:CGSizeMake(128, 128) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
				self.corporationImageView.image = image;
			}];

		
		if (self.allianceImageView && character.allianceID)
			[dataManager imageWithAllianceID:character.allianceID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
				self.allianceImageView.image = image;
			}];
		else
			self.heightConstraint.priority = 999;

	}
	else {
		EVEAPIKeyInfoCharactersItem* character = account.character;
		
		if (self.characterImageView)
			[dataManager imageWithCharacterID:character.characterID preferredSize:CGSizeMake(128, 128) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
				self.characterImageView.image = image;
			}];
		if (self.corporationImageView && character.corporationID)
			[dataManager imageWithCorporationID:character.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
				self.corporationImageView.image = image;
			}];
		if (self.allianceImageView && character.allianceID)
			[dataManager imageWithAllianceID:character.allianceID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(UIImage *image, NSError *error, NSManagedObjectID *cacheRecordID) {
				self.allianceImageView.image = image;
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
