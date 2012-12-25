//
//  BCSearchResultViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BCSearchResultViewController.h"
#import "EVEDBAPI.h"
#import "LoadoutCellView.h"
#import "UITableViewCell+Nib.h"
#import "BattleClinicAPI.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "UIAlertView+Error.h"
#import "Globals.h"
#import "Fit.h"
#import "CharacterEVE.h"
#import "EVEAccount.h"

@implementation BCSearchResultViewController
@synthesize resultsTableView;
@synthesize ship;
@synthesize loadouts;


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
	self.title = NSLocalizedString(@"Search Results", nil);
	shipImage = [[UIImage imageNamed:[ship typeSmallImageName]] retain];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.resultsTableView = nil;
	[shipImage release];
	shipImage = nil;
}


- (void)dealloc {
	[resultsTableView release];
	[ship release];
	[loadouts release];
	[shipImage release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return loadouts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"LoadoutCellView";
	
	LoadoutCellView *cell = (LoadoutCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [LoadoutCellView cellWithNibName:@"LoadoutCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	BCEveLoadoutsListItem *loadout = [loadouts objectAtIndex:indexPath.row];
	cell.titleLabel.text = loadout.subject;
	cell.iconImageView.image = shipImage;
	cell.thumbsUpLabel.text = [NSString stringWithFormat:@"%d,", loadout.thumbsUp];
	cell.thumbsDownLabel.text = [NSString stringWithFormat:@"%d", loadout.thumbsDown];
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Select" name:NSLocalizedString(@"Loading Loadout", nil)];
	__block Fit* fit = nil;
	__block eufe::Character* character = NULL;

	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		NSError *error = nil;
		BCEveLoadoutsListItem *loadout = [loadouts objectAtIndex:indexPath.row];
		operation.progress = 0.2;
		BCEveLoadout *loadoutDetails = [BCEveLoadout eveLoadoutsWithAPIKey:BattleClinicAPIKey loadoutID:loadout.loadoutID error:&error];
		operation.progress = 0.4;
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			if (!loadoutDetails.fitting) {
				UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Unknown error", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil] autorelease];
				[alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				character = new eufe::Character(fittingViewController.fittingEngine);
				operation.progress = 0.6;
				
				EVEAccount* currentAccount = [EVEAccount currentAccount];
				if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
					CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
					character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
					character->setSkillLevels(*[eveCharacter skillsMap]);
				}
				else
					character->setCharacterName("All Skills 0");
				operation.progress = 0.8;
				
				fit = [[Fit fitWithBCString:loadoutDetails.fitting character:character] retain];
				fit.fitName = loadoutDetails.title;
				fit.fitURL =[NSURL URLWithString:[NSString stringWithFormat:@"http://eve.battleclinic.com/loadout/%d.html", loadoutDetails.loadoutID]];
				operation.progress = 1;
			}
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled] && fit && character) {
			fittingViewController.fittingEngine->getGang()->addPilot(character);
			fittingViewController.fit = fit;
			[fittingViewController.fits addObject:fit];
			[self.navigationController pushViewController:fittingViewController animated:YES];
		}
		else {
			if (character)
				delete character;
		}
		[fittingViewController release];
		[fit release];
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end