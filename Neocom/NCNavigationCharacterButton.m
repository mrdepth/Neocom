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
- (void) didChangeAccount:(NSNotification*) notification;
@end

@implementation NCNavigationCharacterButton

- (void) awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:NCAccountDidChangeNotification object:nil];
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

- (void) didChangeAccount:(NSNotification*) notification {
	NCAccount* account = notification.object;
	[self layoutIfNeeded];
	[UIView animateWithDuration:0.35
					 animations:^{
						 self.logoImageView.image = nil;
						 if (account) {
							 if (account.error) {
								 
							 }
							 else if (account.accountType == NCAccountTypeCorporate) {
								 [self.logoImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:account.corporationSheet.corporationID size:EVEImageSize64 error:nil]];
								 self.nameLabel.text = [NSString stringWithFormat:@"%@ [%@]", account.corporationSheet.corporationName, account.corporationSheet.ticker];
								 self.subtitleLabel.text = account.corporationSheet.allianceName;
							 }
							 else {
								 [self.logoImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil]];
								 self.nameLabel.text = account.characterInfo.characterName;
								 self.subtitleLabel.text = account.characterInfo.corporation;
							 }
						 }
						 else {
							 self.nameLabel.text = NSLocalizedString(@"Select account", nil);
							 self.subtitleLabel.text = nil;
						 }
						 [self setNeedsLayout];
						 [self layoutIfNeeded];
					 }];
}

@end
