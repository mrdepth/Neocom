//
//  CharactersViewControllerDelegate.h
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CharactersViewController;
@class Character;

@protocol CharactersViewControllerDelegate <NSObject>

- (void) charactersViewController:(CharactersViewController*) controller didSelectCharacter:(Character*) character;

@end
