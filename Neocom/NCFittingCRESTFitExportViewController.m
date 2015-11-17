//
//  NCFittingCRESTFitExportViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingCRESTFitExportViewController.h"
#import "UIAlertController+Neocom.h"

@interface NCFittingCRESTAccountsViewController ()
@property (nonatomic, strong, readonly) NSArray* tokens;
@end


@interface NCFittingCRESTFitExportViewController ()
@property (nonatomic, assign) BOOL busy;
@end

@implementation NCFittingCRESTFitExportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (!self.busy) {
			CRToken* token = self.tokens[indexPath.row];
			if (token.accessToken) {
				CRAPI* api = [CRAPI apiWithCachePolicy:NSURLRequestUseProtocolCachePolicy clientID:CRAPIClientID secretKey:CRAPISecretKey token:token callbackURL:[NSURL URLWithString:CRAPICallbackURLString]];
				self.busy = YES;
				self.progress = [NSProgress progressWithTotalUnitCount:30];
				[self simulateProgress:self.progress];
				[api postFitting:self.fitting withCompletionBlock:^(BOOL completed, NSError *error) {
					self.progress = nil;
					self.busy = NO;
					if (error)
						[self presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
					else {
						UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Loadout Saved", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
						[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Done", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
							[self performSegueWithIdentifier:@"Unwind" sender:nil];
						}]];
						[self presentViewController:controller animated:YES completion:nil];
					}
				}];
			}
			else
				[UIAlertController alertWithTitle:NSLocalizedString(@"Invalid Token", nil) message:nil];
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
