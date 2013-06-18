//
//  KeysViewController.m
//  EVEUniverse
//
//  Created by Shimanski on 9/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "APIKeysViewController.h"
#import "APIKeysKeyCellView.h"
#import "UITableViewCell+Nib.h"

@implementation APIKeysViewController


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Add API Key", nil);
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	NSIndexSet *indexes = [self.apiKeys indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [[obj valueForKey:@"selected"] boolValue];
	}];
	[self.delegate apiKeysViewController:self didSelectAPIKeys:[self.apiKeys objectsAtIndexes:indexes]];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.keysTableView = nil;
	self.apiKeys = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.apiKeys.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    static NSString *cellIdentifier = @"APIKeysKeyCellView";
    
    APIKeysKeyCellView *cell = (APIKeysKeyCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [APIKeysKeyCellView cellWithNibName:@"APIKeysKeyCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *apiKey = [self.apiKeys objectAtIndex:indexPath.row];
	cell.nameLabel.text = [apiKey valueForKey:@"name"];
	cell.vCodeLabel.text = [apiKey valueForKey:@"vCode"];
	cell.keyIDLabel.text = [apiKey valueForKey:@"keyID"];
	cell.checkmarkImageView.image = [[apiKey valueForKey:@"selected"] boolValue] ? [UIImage imageNamed:@"checkmark.png"] : nil;
    
    // Configure the cell...
    
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	APIKeysKeyCellView *cell = (APIKeysKeyCellView*) [tableView cellForRowAtIndexPath:indexPath];
	NSDictionary *apiKey = [self.apiKeys objectAtIndex:indexPath.row];
	[apiKey setValue:[NSNumber numberWithBool:![[apiKey valueForKey:@"selected"] boolValue]] forKey:@"selected"];
	cell.checkmarkImageView.image = [[apiKey valueForKey:@"selected"] boolValue] ? [UIImage imageNamed:@"checkmark.png"] : nil;
}


@end
