//
//  EVEDBCrtCertificate+TrainingQueue.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEDBCrtCertificate.h"

@class TrainingQueue;
@interface EVEDBCrtCertificate (TrainingQueue)

@property (nonatomic, strong, readonly) TrainingQueue* trainingQueue;

@end
