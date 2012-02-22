//
//  EVEDBCrtCertificate+State.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEDBAPI.h"


typedef enum {
	EVEDBCrtCertificateStateNotLearned,
	EVEDBCrtCertificateStateLowLevel,
	EVEDBCrtCertificateStateLearned
} EVEDBCrtCertificateState;

@interface EVEDBCrtCertificate (State)

@property (nonatomic, assign, readonly) EVEDBCrtCertificateState state;
@property (nonatomic, readonly) NSString* stateIconImageName;

@end
