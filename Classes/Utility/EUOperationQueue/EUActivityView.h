//
//  EUActivityView.h
//  EUOperationQueue
//
//  Created by Artem Shimanski on 28.08.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUOperationQueue.h"

@interface EUActivityView : UIView<EUOperationQueueDelegate>
@end

@interface EUActivityViewController : UIViewController

@end