//
//  NCNavigationCharacterButton.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCNavigationCharacterButton.h"
#import "NCMainMenuContainerViewController.h"
#import "NCAccount.h"
#import "UIImageView+URL.h"

@interface NCNavigationCharacterButton()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NCTaskManager* taskManager;
- (void) didChangeAccount:(NSNotification*) notification;
- (void) setAccount:(NCAccount *)account animated:(BOOL) animated;

@end

@implementation NCNavigationCharacterButton

- (void) awakeFromNib {
	self.taskManager = [NCTaskManager new];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:NCCurrentAccountDidChangeNotification object:nil];
	self.account = [NCAccount currentAccount];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	
	__block __weak void (^weakHighlightView)(UIView*) = nil;
	
	void (^highlightView)(UIView*) = ^(UIView* view) {
		for (id subView in view.subviews) {
			if ([subView respondsToSelector:@selector(setHighlighted:)]) {
				[subView setHighlighted:highlighted];
			}
			weakHighlightView(subView);
		}
	};
	
	weakHighlightView = highlightView;
	
	highlightView(self);
}

- (void) setSelected:(BOOL)selected {
	if (self.selected == selected)
		return;
	
	[super setSelected:selected];
	[UIView animateWithDuration:NCMainMenuDropDownSegueAnimationDuration
						  delay:0
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 self.arrowImageView.transform = CGAffineTransformMakeRotation(selected ? M_PI : 0);
					 }
					 completion:^(BOOL finished) {
						 
					 }];
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	self.logoImageView.image = nil;
	if (account) {
		[account.managedObjectContext performBlock:^{
			if (account.accountType == NCAccountTypeCorporate)
				[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (corporationSheet) {
							[self.logoImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:corporationSheet.corporationID size:EVEImageSizeRetina32 error:nil]];
							self.nameLabel.text = [NSString stringWithFormat:@"%@ [%@]", corporationSheet.corporationName, corporationSheet.ticker];
							self.subtitleLabel.text = corporationSheet.allianceName;
						}
						else if (error) {
							self.nameLabel.text = [error localizedDescription];
							self.subtitleLabel.text = nil;
						}
						else {
							self.nameLabel.text = NSLocalizedString(@"Unknown Error", nil);
							self.subtitleLabel.text = nil;
						}
					});
				}];
			else
				[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (characterInfo) {
							[self.logoImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil]];
							self.nameLabel.text = characterInfo.characterName;
							self.subtitleLabel.text = characterInfo.corporation;
						}
						else if (error) {
							self.nameLabel.text = [error localizedDescription];
							self.subtitleLabel.text = nil;
						}
						else {
							self.nameLabel.text = NSLocalizedString(@"Unknown Error", nil);
							self.subtitleLabel.text = nil;
						}
					});
				}];
		}];
	}
	else {
		self.nameLabel.text = NSLocalizedString(@"Select account", nil);
		self.subtitleLabel.text = nil;
	}
}

- (void) setAccount:(NCAccount *)account animated:(BOOL) animated {
	[self layoutIfNeeded];
	[UIView animateWithDuration:animated ? 0.35f : 0.0f
					 animations:^{
						 self.account = account;
						 [self setNeedsLayout];
						 [self layoutIfNeeded];
					 }];

}

- (void) didChangeAccount:(NSNotification*) notification {
	[self setAccount:notification.object animated:YES];
}

@end
