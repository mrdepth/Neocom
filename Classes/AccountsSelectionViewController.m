//
//  AccountsSelectionViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import "AccountsSelectionViewController.h"
#import "EVEAccountStorage.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "AccountsSelectionCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEOnlineAPI.h"
#import "UIImageView+URL.h"


@interface AccountsSelectionViewController ()
@property (nonatomic, strong) NSArray* accounts;
@end

@implementation AccountsSelectionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Select Characters", nil);
	self.contentSizeForViewInPopover = CGSizeMake(320, 480);
	
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	NSMutableArray* accountsTmp = [NSMutableArray array];
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"AccountsSelectionViewController+Load" name:NSLocalizedString(@"Loading...", nil)];

	[operation addExecutionBlock:^{
		@autoreleasepool {
			for (EVEAccountStorageCharacter* character in [[[EVEAccountStorage sharedAccountStorage] characters] allValues]) {
				if (character.enabled) {
					EVEAccount* account = [EVEAccount accountWithCharacter:character];
					NSMutableDictionary* item = [NSMutableDictionary dictionaryWithObject:account forKey:@"account"];
					
					for (EVEAccount* selectedAccount in self.selectedAccounts) {
						if (account.characterID == selectedAccount.characterID) {
							[item setValue:@(YES) forKey:@"selected"];
							break;
						}
					}
					
					[accountsTmp addObject:item];
				}
			}
			[accountsTmp sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"account.characterName" ascending:YES]]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		self.accounts = accountsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewDidUnload {
	[super viewDidUnload];
	self.accounts = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSMutableArray* selected = [NSMutableArray array];
	for (NSDictionary* account in self.accounts) {
		if ([[account valueForKey:@"selected"] boolValue])
			[selected addObject:[account valueForKey:@"account"]];
	}
	if (selected.count > 0)
		[self.delegate accountsSelectionViewController:self didSelectAccounts:selected];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccountsSelectionCellView";
    AccountsSelectionCellView *cell = (AccountsSelectionCellView*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [AccountsSelectionCellView cellWithNibName:@"AccountsSelectionCellView" bundle:nil reuseIdentifier:CellIdentifier];
	
	NSDictionary* item = [self.accounts objectAtIndex:indexPath.row];
	EVEAccount* account = [item valueForKey:@"account"];
	
	if (RETINA_DISPLAY) {
		[cell.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize128 error:nil] scale:2.0 completion:nil failureBlock:nil];
		[cell.corpImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize64 error:nil] scale:2.0 completion:nil failureBlock:nil];
	}
	else {
		[cell.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSize64 error:nil] scale:1.0 completion:nil failureBlock:nil];
		[cell.corpImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:account.corporationID size:EVEImageSize32 error:nil] scale:1.0 completion:nil failureBlock:nil];
	}
	cell.characterNameLabel.text = account.characterName;
	cell.corpNameLabel.text = account.corporationName;
	//cell.accessoryType = [[item valueForKey:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.accessoryView = [[item valueForKey:@"selected"] boolValue] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSDictionary* item = [self.accounts objectAtIndex:indexPath.row];
	BOOL selected = ![[item valueForKey:@"selected"] boolValue];
	[item setValue:@(selected) forKey:@"selected"];
	AccountsSelectionCellView* cell = (AccountsSelectionCellView*) [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryView = selected ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
}

@end
