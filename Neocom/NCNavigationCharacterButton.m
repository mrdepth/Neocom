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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:NCAccountDidChangeNotification object:nil];
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
		__block EVECorporationSheet* corporationSheet = nil;
		__block EVECharacterInfo* characterInfo = nil;
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 if (account.accountType == NCAccountTypeCorporate)
													 corporationSheet = account.corporationSheet;
												 else
													 characterInfo = account.characterInfo;
											 }
								 completionHandler:^(NCTask *task) {
									 if (account.accountType == NCAccountTypeCorporate) {
										 if (account.corporationSheetError) {
											 self.nameLabel.text = [account.corporationSheetError localizedDescription];
											 self.subtitleLabel.text = nil;
										 }
										 else {
											 [self.logoImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:account.corporationSheet.corporationID size:EVEImageSizeRetina32 error:nil]];
											 self.nameLabel.text = [NSString stringWithFormat:@"%@ [%@]", account.corporationSheet.corporationName, account.corporationSheet.ticker];
											 self.subtitleLabel.text = account.corporationSheet.allianceName;
										 }
									 }
									 else {
										 if (account.characterInfoError) {
											 self.nameLabel.text = [account.characterInfoError localizedDescription];
											 self.subtitleLabel.text = nil;
										 }
										 else {
											 [self.logoImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil]];
											 self.nameLabel.text = account.characterInfo.characterName;
											 self.subtitleLabel.text = account.characterInfo.corporation;
										 }
									 }
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
