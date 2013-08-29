//
//  FittingExportViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.04.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUHTTPServer.h"

@interface FittingExportViewController : UIViewController<EUHTTPServerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;

@end
