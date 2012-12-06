//
//  CertificateTreeView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateTreeView.h"
#import "EVEDBAPI.h"
#import "UIView+Nib.h"
#import "EVEDBCrtCertificate+State.h"
#import "EVEAccount.h"
#import "EUOperationQueue.h"
#import "EVEDBCrtCertificate+TrainingQueue.h"
#import "EVEDBInvType+TrainingQueue.h"
#import "TrainingQueue.h"
#import "NSString+TimeLeft.h"

#define LEFT_MARGIN 10
#define TOP_MARGIN 10
#define INTERCELL_WIDTH 40
#define INTERCELL_HEIGHT 5

@interface CertificateTreeView(Private)
- (UIImage*) imageForState:(EVEDBCrtCertificateState) state;
- (UIColor*) colorForState:(EVEDBCrtCertificateState) state;
- (CertificateRelationshipView*) relationshipViewWithCertificate:(EVEDBCrtCertificate*) certificate;
- (CertificateRelationshipView*) relationshipViewWithRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) loadCertificate;
- (void) loadTrainingTimes;
@end

@implementation CertificateTreeView
@synthesize certificate;
@synthesize prerequisites;
@synthesize derivations;
@synthesize certificateView;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) dealloc {
	[certificate release];
	[prerequisites release];
	[derivations release];
	[certificateView release];
	[super dealloc];
}

- (void) drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);

	if (!certificateView)
		return;

	CGContextSetAllowsAntialiasing(context, NO);
	CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.5);
	
	CGPoint center = CGPointMake(self.bounds.size.width / 2.0, 0);
	UIImage* arrow = [UIImage imageNamed:@"Icons/icon105_05.png"];

	
	for (CertificateRelationshipView* relationshipView in prerequisites) {
		if (relationshipView.center.x < center.x) {
			CGContextMoveToPoint(context, relationshipView.center.x + relationshipView.frame.size.width / 2.0, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x, relationshipView.center.y + relationshipView.frame.size.height + INTERCELL_HEIGHT);
		}
		else {
			CGContextMoveToPoint(context, relationshipView.center.x - relationshipView.frame.size.width / 2.0, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x + 1, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x + 1, relationshipView.center.y + relationshipView.frame.size.height + INTERCELL_HEIGHT);
		}
	}
	
	if (prerequisites.count > 0) {
		center.y = certificateView.center.y - certificateView.frame.size.height / 2.0 - 8;
		[arrow drawAtPoint:CGPointMake(center.x - 15, center.y - 16)];
	}
	
	if (derivations.count > 0) {
		center.y = certificateView.center.y + certificateView.frame.size.height / 2.0 + 8;
		[arrow drawAtPoint:CGPointMake(center.x - 15, center.y - 16)];
	}
	
	for (CertificateRelationshipView* relationshipView in derivations) {
		if (relationshipView.center.x < center.x) {
			CGContextMoveToPoint(context, relationshipView.center.x + relationshipView.frame.size.width / 2.0, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x, relationshipView.center.y - relationshipView.frame.size.height - INTERCELL_HEIGHT);
		}
		else {
			CGContextMoveToPoint(context, relationshipView.center.x - relationshipView.frame.size.width / 2.0, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x + 1, relationshipView.center.y);
			CGContextAddLineToPoint(context, center.x + 1, relationshipView.center.y - relationshipView.frame.size.height - INTERCELL_HEIGHT);
		}
	}

	CGContextStrokePath(context);
}

- (void) setCertificate:(EVEDBCrtCertificate *)value {
	[value retain];
	[certificate release];
	certificate = value;
	
	[prerequisites release];
	[derivations release];
	prerequisites = [[NSMutableArray alloc] init];
	derivations = [[NSMutableArray alloc] init];
	[certificateView release];
	certificateView = nil;
	
	if (!certificate)
		return;
	
	for (UIView* view in [self subviews])
		[view removeFromSuperview];
	[self setNeedsDisplay];
	[self loadCertificate];
}

- (IBAction)onAddToTrainingPlan {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Add to skill plan?"
														message:[NSString stringWithFormat:@"Training time: %@", [NSString stringWithTimeLeft:certificate.trainingQueue.trainingTime]]
													   delegate:self
											  cancelButtonTitle:@"No"
											  otherButtonTitles:@"Yes", nil];
	[alertView show];
	[alertView release];
}

#pragma mark CertificateRelationshipViewDelegate

- (void) certificateRelationshipViewDidTap:(CertificateRelationshipView*) relationshipView {
	if (relationshipView.certificate != NULL)
		[delegate certificateTreeView:self didSelectCertificate:relationshipView.certificate];
	else if (relationshipView.type != NULL)
		[delegate certificateTreeView:self didSelectType:relationshipView.type];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		SkillPlan* skillPlan = [[EVEAccount currentAccount] skillPlan];
		for (EVEDBInvTypeRequiredSkill* skill in certificate.trainingQueue.skills)
			[skillPlan addSkill:skill];
		[skillPlan save];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Skill plan updated"
															message:[NSString stringWithFormat:@"Total training time: %@", [NSString stringWithTimeLeft:skillPlan.trainingTime]]
														   delegate:nil
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView autorelease];
	}
}

@end

@implementation CertificateTreeView(Private)

- (UIImage*) imageForState:(EVEDBCrtCertificateState) state {
	switch (state) {
		case EVEDBCrtCertificateStateLearned:
			return [UIImage imageNamed:@"Icons/icon38_193.png"];
		case EVEDBCrtCertificateStateNotLearned:
			return [UIImage imageNamed:@"Icons/icon38_194.png"];
		default:
			return [UIImage imageNamed:@"Icons/icon38_195.png"];
	}
}

- (UIColor*) colorForState:(EVEDBCrtCertificateState) state {
	switch (state) {
		case EVEDBCrtCertificateStateLearned:
			return [UIColor colorWithRed:37.0/255.0 green:41.0/255.0 blue:36.0/255.0 alpha:1.0];
		case EVEDBCrtCertificateStateNotLearned:
			return [UIColor colorWithRed:28.0/255.0 green:17.0/255.0 blue:16.0/255.0 alpha:1.0];
		default:
			return [UIColor colorWithRed:27.0/255.0 green:27.0/255.0 blue:10.0/255.0 alpha:1.0];
	}
}

- (CertificateRelationshipView*) relationshipViewWithCertificate:(EVEDBCrtCertificate*) aCertificate {
	CertificateRelationshipView* relationshipView = [CertificateRelationshipView viewWithNibName:@"CertificateRelationshipView" bundle:nil];
	relationshipView.certificate = aCertificate;
	relationshipView.delegate = self;
	relationshipView.iconView.image = [UIImage imageNamed:[aCertificate iconImageName]];
	relationshipView.statusView.image = [UIImage imageNamed:aCertificate.stateIconImageName];
	relationshipView.color = [self colorForState:aCertificate.state];
	relationshipView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", aCertificate.certificateClass.className, aCertificate.gradeText];

	return relationshipView;
}

- (CertificateRelationshipView*) relationshipViewWithRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill {
	CertificateRelationshipView* relationshipView = [CertificateRelationshipView viewWithNibName:@"CertificateRelationshipView" bundle:nil];
	relationshipView.type = skill;
	relationshipView.delegate = self;

	EVEAccount* account = [EVEAccount currentAccount];
	EVEDBCrtCertificateState state;
	
	if (!account || !account.characterSheet)
		state = EVEDBCrtCertificateStateNotLearned;
	else {
		EVECharacterSheetSkill* characterSkill = [account.characterSheet.skillsMap valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
		if (!characterSkill)
			state = EVEDBCrtCertificateStateNotLearned;
		else if (characterSkill.level < skill.requiredLevel)
			state = EVEDBCrtCertificateStateLowLevel;
		else
			state = EVEDBCrtCertificateStateLearned;
	}
	
	relationshipView.iconView.image = [UIImage imageNamed:@"Icons/icon50_11.png"];
	relationshipView.statusView.image = [self imageForState:state];
	relationshipView.color = [self colorForState:state];
	[skill.trainingQueue addSkill:skill];
	relationshipView.titleLabel.text = [NSString stringWithFormat:@"%@\nLevel %d", skill.typeName, skill.requiredLevel];

	return relationshipView;
}

- (void) loadCertificate {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateTreeView+loadCertificate" name:@"Loading Certificate"];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[certificate state];
		[certificate certificateClass];
		float n = certificate.prerequisites.count;
		float i = 0;
		for (EVEDBCrtRelationship* relationship in certificate.prerequisites) {
			operation.progress = i++ / n / 2;
			if (relationship.parent) {
				[relationship.parent state];
				[relationship.parent certificateClass];
			}
		}
		
		n = certificate.derivations.count;
		i = 0;
		for (EVEDBCrtRelationship* relationship in certificate.derivations) {
			operation.progress = 0.5 + i++ / n / 2;
			if (relationship.child) {
				[relationship.child state];
				[relationship.child certificateClass];
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		certificateView = [[CertificateView viewWithNibName:@"CertificateView" bundle:nil] retain];
		certificateView.iconView.image = [UIImage imageNamed:[certificate iconImageName]];
		certificateView.statusView.image = [UIImage imageNamed:certificate.stateIconImageName];
		certificateView.color = [self colorForState:certificate.state];
		
		if (certificate.state == EVEDBCrtCertificateStateLearned) {
			certificateView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", certificate.certificateClass.className, certificate.gradeText];
			certificateView.descriptionLabel.text = certificate.description;
		}
		else {
			if ([[EVEAccount currentAccount] skillPlan]) {
				certificateView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@ (Tap to add to training plan)", certificate.certificateClass.className, certificate.gradeText];
				UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAddToTrainingPlan)];
				[certificateView addGestureRecognizer:tapGestureRecognizer];
				[tapGestureRecognizer release];
			}
			else
				certificateView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", certificate.certificateClass.className, certificate.gradeText];

			certificateView.descriptionLabel.text = [NSString stringWithFormat:@"Training time: \n\n%@", certificate.description];
		}
		
		[certificateView sizeToFit];
		
		CGSize cellSize = CGSizeZero;
		
		for (EVEDBCrtRelationship* relationship in certificate.prerequisites) {
			if (relationship.parent)
				[prerequisites addObject:[self relationshipViewWithCertificate:relationship.parent]];
			else if (relationship.parentType)
				[prerequisites addObject:[self relationshipViewWithRequiredSkill:relationship.parentType]];
		}
		
		for (EVEDBCrtRelationship* relationship in certificate.derivations) {
			if (relationship.child)
				[derivations addObject:[self relationshipViewWithCertificate:relationship.child]];
		}
		
		if (prerequisites.count > 0)
			cellSize = [[prerequisites objectAtIndex:0] frame].size;
		else if (derivations.count > 0)
			cellSize = [[derivations objectAtIndex:0] frame].size;
		
		CGPoint center = CGPointMake(cellSize.width / 2.0 + LEFT_MARGIN, cellSize.height / 2.0 + TOP_MARGIN);
		BOOL nextRow = prerequisites.count % 2 != 0;
		
		for (CertificateRelationshipView* relationshipView in prerequisites) {
			relationshipView.center = center;
			[self addSubview:relationshipView];
			if (nextRow) {
				center = CGPointMake(cellSize.width / 2.0 + LEFT_MARGIN, center.y + cellSize.height + INTERCELL_HEIGHT);
				nextRow = NO;
			}
			else {
				center = CGPointMake(cellSize.width * 1.5 + LEFT_MARGIN + INTERCELL_WIDTH, center.y);
				nextRow = YES;
			}
		}
		
		certificateView.center = CGPointMake(cellSize.width + LEFT_MARGIN + INTERCELL_WIDTH / 2.0, center.y + certificateView.frame.size.height / 2.0 + 20);
		[self addSubview:certificateView];
		
		center.y = certificateView.center.y + certificateView.frame.size.height / 2.0 + 20 + cellSize.height / 2.0 + INTERCELL_HEIGHT + 20;
		
		nextRow = NO;
		
		for (CertificateRelationshipView* relationshipView in derivations) {
			relationshipView.center = center;
			[self addSubview:relationshipView];
			if (nextRow) {
				center = CGPointMake(cellSize.width / 2.0 + LEFT_MARGIN, center.y + cellSize.height + INTERCELL_HEIGHT);
				nextRow = NO;
			}
			else {
				center = CGPointMake(cellSize.width * 1.5 + LEFT_MARGIN + INTERCELL_WIDTH, center.y);
				nextRow = YES;
			}
		}
		
		if (nextRow)
			center = CGPointMake(cellSize.width / 2.0 + LEFT_MARGIN, center.y + cellSize.height / 2.0);
		else
			center.y -= cellSize.height / 2.0 - INTERCELL_HEIGHT;
		
		self.bounds = CGRectMake(0, 0, cellSize.width * 2 + LEFT_MARGIN * 2 + INTERCELL_WIDTH, center.y + 50 + TOP_MARGIN);
		[delegate certificateTreeViewDidFinishLoad:self];
		[self setNeedsDisplay];
		[self performSelector:@selector(loadTrainingTimes) withObject:nil afterDelay:0];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) loadTrainingTimes {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateTreeView+loadTrainingTimes" name:@"Calculating Training Time"];
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

		NSTimeInterval trainingTime = certificate.trainingQueue.trainingTime;
		if (trainingTime > 0)
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				certificateView.descriptionLabel.text = [NSString stringWithFormat:@"Training time: %@\n\n%@", [NSString stringWithTimeLeft:trainingTime], certificate.description];
			}];
		
		float n = prerequisites.count + derivations.count;
		float i = 0;
		for (CertificateRelationshipView* relationshipView in [prerequisites arrayByAddingObjectsFromArray:derivations]) {
			operation.progress = i++ / n;
			if ([operation isCancelled])
				break;
			NSString* text = nil;
			if (relationshipView.certificate) {
				NSTimeInterval trainingTime = relationshipView.certificate.trainingQueue.trainingTime;
				if (trainingTime > 0)
					text = [NSString stringWithFormat:@"%@\n%@ (Training time: %@)", relationshipView.certificate.certificateClass.className, relationshipView.certificate.gradeText, [NSString stringWithTimeLeft:trainingTime]];
			}
			else if (relationshipView.type) {
				NSTimeInterval trainingTime = relationshipView.type.trainingQueue.trainingTime;
				if (trainingTime > 0)
					text = [NSString stringWithFormat:@"%@\nLevel %d (Training time: %@)", relationshipView.type.typeName, relationshipView.type.requiredLevel, [NSString stringWithTimeLeft:trainingTime]];
			}
			if (text)
				[relationshipView.titleLabel performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];

		}
		[pool release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end