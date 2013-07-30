//
//  EVEAPIKeysViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 22.07.13.
//
//

#import "EVEAPIKeysViewController.h"
#import "GroupedCell.h"
#import "APIKey.h"
#import "appearance.h"
#import "UIColor+NSNumber.h"
#import "AccessMaskViewController.h"
#import "EVEAccountsManager.h"

@interface EVEAPIKeysViewController ()

@end

@implementation EVEAPIKeysViewController

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
	self.clearsSelectionOnViewWillAppear = YES;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return self.apiKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.font = [UIFont systemFontOfSize:12];
		cell.textLabel.shadowColor = [UIColor blackColor];
		cell.textLabel.textColor = [UIColor whiteColor];

		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.numberOfLines = 2;
    }
	
	APIKey* apiKey = [self.apiKeys objectAtIndex:indexPath.row];
	if (apiKey.apiKeyInfo) {
		NSString* keyType = nil;
		if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeAccount)
			keyType = @"Account";
		else if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCharacter)
			keyType = @"Char";
		else if (apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
			keyType = @"Corp";
		else
			keyType = @"Unknown";
		
		cell.textLabel.text = [NSString stringWithFormat:@"%@ key %d (%d characters)\nAccess mask %d", keyType, apiKey.keyID, apiKey.apiKeyInfo.characters.count, apiKey.apiKeyInfo.key.accessMask];
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:@"Key %d\n%@", apiKey.keyID, [apiKey.error localizedDescription]];
	}

	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
    
    // Configure the cell...
    
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		APIKey* apiKey = apiKey = self.apiKeys[indexPath.row];
		[[EVEAccountsManager sharedManager] removeAPIKeyWithKeyID:apiKey.keyID];
		
		NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, self.apiKeys.count)];
		[indexSet removeIndex:indexPath.row];
		self.apiKeys = [self.apiKeys objectsAtIndexes:indexSet];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		if (self.apiKeys.count == 0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
			[self.navigationController popViewControllerAnimated:YES];
    }
}


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
	AccessMaskViewController* controller = [[AccessMaskViewController alloc] initWithNibName:@"AccessMaskViewController" bundle:nil];
	APIKey* apiKey = self.apiKeys[indexPath.row];
	controller.accessMask = apiKey.apiKeyInfo.key.accessMask;
	controller.apiKeyType = apiKey.apiKeyInfo.key.type;
	[self.navigationController pushViewController:controller animated:YES];
}

@end
