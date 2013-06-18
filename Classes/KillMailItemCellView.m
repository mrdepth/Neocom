//
//  KillMailItemCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import "KillMailItemCellView.h"

@implementation KillMailItemCellView

- (void) setDestroyed:(BOOL)destroyed {
	_destroyed = destroyed;
	[(UIImageView*) self.backgroundView setImage:[UIImage imageNamed:destroyed ? @"cellBackground.png" : @"cellBackgroundDropped.png"]];
}

@end
