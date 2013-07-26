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

@interface CertificateTreeView()
@property (strong, nonatomic, readwrite) NSMutableArray* prerequisites;
@property (strong, nonatomic, readwrite) NSMutableArray* derivations;
@property (strong, nonatomic, readwrite) CertificateView* certificateView;

- (UIImage*) imageForState:(EVEDBCrtCertificateState) state;
- (UIColor*) colorForState:(EVEDBCrtCertificateState) state;
- (CertificateRelationshipView*) relationshipViewWithCertificate:(EVEDBCrtCertificate*) certificate;
- (CertificateRelationshipView*) relationshipViewWithRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill;
- (void) loadCertificate;
- (void) loadTrainingTimes;
@end

@implementation CertificateTreeView

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

- (void) drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);

	if (!self.certificateView)
		return;

	CGContextSetAllowsAntialiasing(context, NO);
	CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.5);
	
	CGPoint center = CGPointMake(self.bounds.size.width / 2.0, 0);
	UIImage* arrow = [UIImage imageNamed:@"Icons/icon105_05.png"];

	
	for (CertificateRelationshipView* relationshipView in self.prerequisites) {
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
	
	if (self.prerequisites.count > 0) {
		center.y = self.certificateView.center.y - self.certificateView.frame.size.height / 2.0 - 8;
		[arrow drawAtPoint:CGPointMake(center.x - 15, center.y - 16)];
	}
	
	if (self.derivations.count > 0) {
		center.y = self.certificateView.center.y + self.certificateView.frame.size.height / 2.0 + 8;
		[arrow drawAtPoint:CGPointMake(center.x - 15, center.y - 16)];
	}
	
	for (CertificateRelationshipView* relationshipView in self.derivations) {
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
	_certificate = value;
	
	self.prerequisites = [[NSMutableArray alloc] init];
	self.derivations = [[NSMutableArray alloc] init];
	self.certificateView = nil;
	
	if (!self.certificate)
		return;
	
	for (UIView* view in [self subviews])
		[view removeFromSuperview];
	[self setNeedsDisplay];
	[self loadCertificate];
}

- (IBAction)onAddToTrainingPlan {
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
														message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.certificate.trainingQueue.trainingTime]]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"No", nil)
											  otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
	[alertView show];
}

#pragma mark CertificateRelationshipViewDelegate

- (void) certificateRelationshipViewDidTap:(CertificateRelationshipView*) relationshipView {
	if (relationshipView.certificate != NULL)
		[self.delegate certificateTreeView:self didSelectCertificate:relationshipView.certificate];
	else if (relationshipView.type != NULL)
		[self.delegate certificateTreeView:self didSelectType:relationshipView.type];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		SkillPlan* skillPlan = [[EVEAccount currentAccount] skillPlan];
		for (EVEDBInvTypeRequiredSkill* skill in self.certificate.trainingQueue.skills)
			[skillPlan addSkill:skill];
		[skillPlan save];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Skill plan updated", nil)
															message:[NSString stringWithFormat:NSLocalizedString(@"Total training time: %@", nil), [NSString stringWithTimeLeft:skillPlan.trainingTime]]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
												  otherButtonTitles:nil];
		[alertView show];
	}
}

#pragma mark - Private

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
	relationshipView.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\nLevel %d", nil), skill.typeName, skill.requiredLevel];

	return relationshipView;
}

- (void) loadCertificate {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateTreeView+loadCertificate" name:NSLocalizedString(@"Loading Certificate", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		[self.certificate state];
		[self.certificate certificateClass];
		float n = self.certificate.prerequisites.count;
		float i = 0;
		for (EVEDBCrtRelationship* relationship in self.certificate.prerequisites) {
			weakOperation.progress = i++ / n / 2;
			if (relationship.parent) {
				[relationship.parent state];
				[relationship.parent certificateClass];
			}
		}
		
		n = self.certificate.derivations.count;
		i = 0;
		for (EVEDBCrtRelationship* relationship in self.certificate.derivations) {
			weakOperation.progress = 0.5 + i++ / n / 2;
			if (relationship.child) {
				[relationship.child state];
				[relationship.child certificateClass];
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		self.certificateView = [CertificateView viewWithNibName:@"CertificateView" bundle:nil];
		self.certificateView.iconView.image = [UIImage imageNamed:[self.certificate iconImageName]];
		self.certificateView.statusView.image = [UIImage imageNamed:self.certificate.stateIconImageName];
		self.certificateView.color = [self colorForState:self.certificate.state];
		
		if (self.certificate.state == EVEDBCrtCertificateStateLearned) {
			self.certificateView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", self.certificate.certificateClass.className, self.certificate.gradeText];
			self.certificateView.descriptionLabel.text = self.certificate.description;
		}
		else {
			if ([[EVEAccount currentAccount] skillPlan]) {
				self.certificateView.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\n%@ (Tap to add to training plan)", nil), self.certificate.certificateClass.className, self.certificate.gradeText];
				UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAddToTrainingPlan)];
				[self.certificateView addGestureRecognizer:tapGestureRecognizer];
			}
			else
				self.certificateView.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", self.certificate.certificateClass.className, self.certificate.gradeText];

			self.certificateView.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Training time: \n\n%@", nil), self.certificate.description];
		}
		
		[self.certificateView sizeToFit];
		
		CGSize cellSize = CGSizeZero;
		
		for (EVEDBCrtRelationship* relationship in self.certificate.prerequisites) {
			if (relationship.parent)
				[self.prerequisites addObject:[self relationshipViewWithCertificate:relationship.parent]];
			else if (relationship.parentType)
				[self.prerequisites addObject:[self relationshipViewWithRequiredSkill:relationship.parentType]];
		}
		
		for (EVEDBCrtRelationship* relationship in self.certificate.derivations) {
			if (relationship.child)
				[self.derivations addObject:[self relationshipViewWithCertificate:relationship.child]];
		}
		
		if (self.prerequisites.count > 0)
			cellSize = [[self.prerequisites objectAtIndex:0] frame].size;
		else if (self.derivations.count > 0)
			cellSize = [[self.derivations objectAtIndex:0] frame].size;
		
		CGPoint center = CGPointMake(cellSize.width / 2.0 + LEFT_MARGIN, cellSize.height / 2.0 + TOP_MARGIN);
		BOOL nextRow = self.prerequisites.count % 2 != 0;
		
		for (CertificateRelationshipView* relationshipView in self.prerequisites) {
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
		
		self.certificateView.center = CGPointMake(cellSize.width + LEFT_MARGIN + INTERCELL_WIDTH / 2.0, center.y + self.certificateView.frame.size.height / 2.0 + 20);
		[self addSubview:self.certificateView];
		
		center.y = self.certificateView.center.y + self.certificateView.frame.size.height / 2.0 + 20 + cellSize.height / 2.0 + INTERCELL_HEIGHT + 20;
		
		nextRow = NO;
		
		for (CertificateRelationshipView* relationshipView in self.derivations) {
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
		[self.delegate certificateTreeViewDidFinishLoad:self];
		[self setNeedsDisplay];
		[self performSelector:@selector(loadTrainingTimes) withObject:nil afterDelay:0];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) loadTrainingTimes {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateTreeView+loadTrainingTimes" name:NSLocalizedString(@"Calculating Training Time", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		NSTimeInterval trainingTime = self.certificate.trainingQueue.trainingTime;
		if (trainingTime > 0)
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				self.certificateView.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@\n\n%@", nil), [NSString stringWithTimeLeft:trainingTime], self.certificate.description];
			}];
		
		float n = self.prerequisites.count + self.derivations.count;
		float i = 0;
		for (CertificateRelationshipView* relationshipView in [self.prerequisites arrayByAddingObjectsFromArray:self.derivations]) {
			weakOperation.progress = i++ / n;
			if ([weakOperation isCancelled])
				break;
			NSString* text = nil;
			if (relationshipView.certificate) {
				NSTimeInterval trainingTime = relationshipView.certificate.trainingQueue.trainingTime;
				if (trainingTime > 0)
					text = [NSString stringWithFormat:NSLocalizedString(@"%@\n%@ (Training time: %@)", nil), relationshipView.certificate.certificateClass.className, relationshipView.certificate.gradeText, [NSString stringWithTimeLeft:trainingTime]];
			}
			else if (relationshipView.type) {
				NSTimeInterval trainingTime = relationshipView.type.trainingQueue.trainingTime;
				if (trainingTime > 0)
					text = [NSString stringWithFormat:NSLocalizedString(@"%@\nLevel %d (Training time: %@)", nil), relationshipView.type.typeName, relationshipView.type.requiredLevel, [NSString stringWithTimeLeft:trainingTime]];
			}
			if (text)
				[relationshipView.titleLabel performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];

		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end