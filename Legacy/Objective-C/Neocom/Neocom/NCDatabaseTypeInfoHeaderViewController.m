//
//  NCDatabaseTypeInfoHeaderViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeInfoHeaderViewController.h"
#import "NCDatabase.h"
#import "UIColor+CS.h"
#import "NSAttributedString+NC.h"
@import CoreText;


@interface NCDatabaseTypeInfoHeaderViewController ()

@end

@implementation NCDatabaseTypeInfoHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.titleLabel.text = self.type.typeName ?: NSLocalizedString(@"Unknown", nil);
	/*NSString* typeName = self.type.typeName ?: NSLocalizedString(@"Unknown", nil);
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %d", typeName, self.type.typeID]];
	NSRange typeIDRange = NSMakeRange(typeName.length + 1, title.length - typeName.length - 1);
	[title addAttributes:@{NSFontAttributeName: [self.titleLabel.font fontWithSize:self.titleLabel.font.pointSize * 0.4],
						  // (__bridge NSString*) (kCTSuperscriptAttributeName): @(-1),
						   NSForegroundColorAttributeName: [UIColor lightTextColor]}
				   range:typeIDRange];
	

	
	
	self.titleLabel.attributedText = title;*/
	self.textView.attributedText = [self.type.typeDescription.text attributedStringWithDefaultFont:self.textView.font textColor:self.textView.textColor];
	self.imageView.image = (id) self.type.icon.image.image ?: NCDBEveIcon.defaultTypeIcon.image.image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
