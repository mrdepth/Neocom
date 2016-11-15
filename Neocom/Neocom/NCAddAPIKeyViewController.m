//
//  NCAddAPIKeyViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAddAPIKeyViewController.h"
#import "NCSheetPresentationController.h"
#import "UIColor+NC.h"
#import "NCDataManager.h"
#import "NCAddAPIKeyCell.h"

@interface NCAddAPIKeyViewController ()
@property (nonatomic, strong) EVEAPIKeyInfo* apiKeyInfo;
@property (nonatomic, strong) EVEAPIKey* currentAPIKey;
@property (nonatomic, strong) NSMutableIndexSet* disabledCharacters;
@end

@implementation NCAddAPIKeyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.tableView.backgroundColor = [UIColor backgroundColor];
	self.navigationController.preferredContentSize = CGSizeMake(320, 320);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSave:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSafari:(id)sender {
}

- (IBAction)onSwitch:(id)sender {
	NCAddAPIKeyCell* cell;
	for (cell = (id) [sender superview]; cell && ![cell isKindOfClass:[NCAddAPIKeyCell class]]; cell = (id) cell.superview);
	if (!cell)
		return;
	
	EVEAPIKeyInfoCharactersItem* item = cell.object;
	if ([(UISwitch*) sender isOn])
		[self.disabledCharacters removeIndex:item.characterID];
	else
		[self.disabledCharacters addIndex:item.characterID];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.apiKeyInfo.key.characters.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAddAPIKeyCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	EVEAPIKeyInfoCharactersItem* item = self.apiKeyInfo.key.characters[indexPath.row];
	cell.object = item;
	cell.imageView.image = nil;
	cell.switchControl.on = ![self.disabledCharacters containsIndex:item.characterID];
	if (self.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation) {
		cell.titleLabel.text = item.corporationName;
		cell.subtitleLabel.text = item.allianceName;
		cell.imageView.clipsToBounds = NO;
	}
	else {
		cell.imageView.clipsToBounds = YES;
		cell.titleLabel.text = item.characterName;
		cell.subtitleLabel.text = item.corporationName;
		[[NCDataManager new] imageWithCharacterID:item.characterID preferredSize:cell.iconView.bounds.size scale:[[UIScreen mainScreen] scale] completionBlock:^(UIImage *image, NSError *error) {
			if (cell.object == item)
				cell.imageView.image = image;
		}];
	}
	return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.keyIDTextField)
		[self.vCodeTextField becomeFirstResponder];
	else {
		[textField endEditing:YES];
		[self loadCharacters];
	}
	return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadCharacters) object:nil];
	[self performSelector:@selector(loadCharacters) withObject:nil afterDelay:2];
	return YES;
}

#pragma mark - Private

- (EVEAPIKey*) apiKey {
	int32_t keyID = [self.keyIDTextField.text intValue];
	NSString* vCode = [self.vCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (keyID > 0 && vCode.length > 1)
		return [[EVEAPIKey alloc] initWithKeyID:keyID vCode:vCode];
	else
		return nil;
}

- (void) loadCharacters {
	EVEAPIKey* apiKey = [self apiKey];
	if (apiKey) {
		if ([self.activityIndicator isAnimating])
			return;
		if (apiKey.keyID == self.currentAPIKey.keyID && [apiKey.vCode isEqualToString:self.currentAPIKey.vCode])
			return;
		
		
		[self.activityIndicator startAnimating];
		[[NCDataManager new] apiKeyInfoWithKeyID:apiKey.keyID vCode:apiKey.vCode completionBlock:^(EVEAPIKeyInfo *apiKeyInfo, NSError *error) {
			EVEAPIKey* newKey = [self apiKey];
			if (apiKey.keyID == newKey.keyID && [apiKey.vCode isEqualToString:newKey.vCode]) {
				self.apiKeyInfo = apiKeyInfo;
				self.currentAPIKey = apiKey;
				self.disabledCharacters = [NSMutableIndexSet new];
			}
			else {
				self.apiKeyInfo = nil;
				self.currentAPIKey = nil;
				[self.activityIndicator stopAnimating];
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadCharacters) object:nil];
				[self loadCharacters];
			}
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
			[self.activityIndicator stopAnimating];
		}];
	}
}

- (void) setApiKeyInfo:(EVEAPIKeyInfo *)apiKeyInfo {
	_apiKeyInfo = apiKeyInfo;
	self.navigationItem.rightBarButtonItem.enabled = apiKeyInfo != nil;
}

@end
