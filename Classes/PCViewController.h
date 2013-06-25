//
//  PCViewController.h
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUHTTPServer.h"

@interface PCViewController : UIViewController<EUHTTPServerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;

@end
