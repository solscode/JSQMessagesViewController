//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesCollectionViewCell.h"

#import "JSQMessagesCollectionViewCellIncoming.h"
#import "JSQMessagesCollectionViewCellOutgoing.h"
#import "JSQMessagesCollectionViewLayoutAttributes.h"

#import "UIView+JSQMessages.h"
#import "UIDevice+JSQMessages.h"


static NSMutableSet *jsqMessagesCollectionViewCellActions = nil;


@interface JSQMessagesCollectionViewCell ()

@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellTopLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellTopBelowLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *messageBubbleTopLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellBottomLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellBottomCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *cellBottomFailButton;

@property (weak, nonatomic) IBOutlet UIView *messageBubbleContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *messageBubbleImageView;
@property (weak, nonatomic) IBOutlet JSQMessagesCellTextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *systemNotificationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *avatarContainerView;

@property (weak, nonatomic) IBOutlet UIButton *gotoSystemNotificationTitledButton;
@property (weak, nonatomic) IBOutlet UIView *gotoSystemNotificationButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIView *gotoSystemNotificationButtonsView;
@property (weak, nonatomic) IBOutlet UIView *gotoSystemNotificationButtonsLineView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleContainerWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTopVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewAvatarHorizontalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewMarginHorizontalSpaceConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopBelowLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopLabelToCellTopBelowLabelVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopBelowLabelToMessagesBubbleTopLabelVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopBelowLabelToAvatarVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBottomLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBottomCountLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBottomFailButtonHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gotoSystemNotificationButtonsContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *systemNotificationImageViewHeightConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *bubbleContainerAvatarHorizontalSpaceConstraint;


@property (assign, nonatomic) UIEdgeInsets textViewFrameInsets;

@property (assign, nonatomic) CGSize avatarViewSize;

@property (weak, nonatomic, readwrite) UITapGestureRecognizer *tapGestureRecognizer;

- (void)jsq_handleTapGesture:(UITapGestureRecognizer *)tap;

- (void)jsq_updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant;

- (IBAction)failButtonPressed:(id)sender;

- (IBAction)gotoSystemNotificationButtonPressed:(id)sender;

@end


@implementation JSQMessagesCollectionViewCell

#pragma mark - Class methods

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsqMessagesCollectionViewCellActions = [NSMutableSet new];
    });
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (NSString *)mediaCellReuseIdentifier
{
    return [NSString stringWithFormat:@"%@_JSQMedia", NSStringFromClass([self class])];
}

+ (void)registerMenuAction:(SEL)action
{
    [jsqMessagesCollectionViewCellActions addObject:NSStringFromSelector(action)];
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.backgroundColor = [UIColor whiteColor];

    self.cellTopLabelHeightConstraint.constant = 0.0f;
    self.messageBubbleTopLabelHeightConstraint.constant = 0.0f;
    self.cellBottomLabelHeightConstraint.constant = 0.0f;
    self.cellBottomCountLabelHeightConstraint.constant = 0.0f;
    self.cellBottomFailButtonHeightConstraint.constant = 0.0f;

    self.avatarViewSize = CGSizeZero;

    self.cellTopLabel.textAlignment = NSTextAlignmentCenter;
    self.cellTopLabel.font = [UIFont systemFontOfSize:12.0f];
    self.cellTopLabel.textColor = [UIColor lightGrayColor];
    
    self.cellTopBelowLabel.textAlignment = NSTextAlignmentCenter;
    self.cellTopBelowLabel.font = [UIFont systemFontOfSize:12.0f];
    self.cellTopBelowLabel.textColor = [UIColor lightGrayColor];

    self.messageBubbleTopLabel.font = [UIFont systemFontOfSize:13.0f];
    self.messageBubbleTopLabel.textColor = [UIColor lightGrayColor];

    self.cellBottomLabel.font = [UIFont systemFontOfSize:10.0f];
    self.cellBottomLabel.textColor = [UIColor lightGrayColor];
    self.cellBottomCountLabel.font = [UIFont systemFontOfSize:9.0f];
    self.cellBottomCountLabel.textColor = [UIColor lightGrayColor];
    
    self.systemNotificationImageViewHeightConstraint.constant = 0.0f;
    self.gotoSystemNotificationButtonsContainerViewHeightConstraint.constant = 0.0f;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jsq_handleTapGesture:)];
    [self addGestureRecognizer:tap];
    self.tapGestureRecognizer = tap;
}

- (void)dealloc
{
    _delegate = nil;

    _cellTopLabel = nil;
    _cellTopBelowLabel = nil;
    _messageBubbleTopLabel = nil;
    _cellBottomLabel = nil;
    _cellBottomCountLabel = nil;
    _cellBottomFailButton = nil;

    _textView = nil;
    _messageBubbleImageView = nil;
    _mediaView = nil;

    _avatarImageView = nil;
    
    _systemNotificationImageView = nil;
    _gotoSystemNotificationTitledButton = nil;
    _gotoSystemNotificationButtonsContainerView = nil;
    _gotoSystemNotificationButtonsView = nil;
    _gotoSystemNotificationButtonsLineView = nil;
    
    [_tapGestureRecognizer removeTarget:nil action:NULL];
    _tapGestureRecognizer = nil;
}

#pragma mark - Collection view cell

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.cellTopLabel.text = nil;
    self.cellTopBelowLabel.text = nil;
    self.messageBubbleTopLabel.text = nil;
    self.cellBottomLabel.text = nil;
    self.cellBottomCountLabel.text = nil;

    self.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.textView.text = nil;
    self.textView.attributedText = nil;
    self.textView.userInteractionEnabled = NO;

    self.avatarImageView.image = nil;
    self.avatarImageView.highlightedImage = nil;
    
    self.gotoSystemNotificationTitledButton.titleLabel.text = nil;
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    return layoutAttributes;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    JSQMessagesCollectionViewLayoutAttributes *customAttributes = (JSQMessagesCollectionViewLayoutAttributes *)layoutAttributes;

    if (self.textView.font != customAttributes.messageBubbleFont) {
        self.textView.font = customAttributes.messageBubbleFont;
    }

    if (!UIEdgeInsetsEqualToEdgeInsets(self.textView.textContainerInset, customAttributes.textViewTextContainerInsets)) {
        self.textView.textContainerInset = customAttributes.textViewTextContainerInsets;
    }

    self.textViewFrameInsets = customAttributes.textViewFrameInsets;

    [self jsq_updateConstraint:self.messageBubbleContainerWidthConstraint
                  withConstant:customAttributes.messageBubbleContainerViewWidth];

    [self jsq_updateConstraint:self.cellTopLabelHeightConstraint
                  withConstant:customAttributes.cellTopLabelHeight];

    [self jsq_updateConstraint:self.cellTopBelowLabelHeightConstraint
                  withConstant:customAttributes.cellTopBelowLabelHeight];
    
    [self jsq_updateConstraint:self.cellTopLabelToCellTopBelowLabelVerticalSpaceConstraint withConstant:customAttributes.cellTopLabelToCellTopBelowLabelVerticalSpace];
    [self jsq_updateConstraint:self.cellTopBelowLabelToMessagesBubbleTopLabelVerticalSpaceConstraint withConstant:customAttributes.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace];
    [self jsq_updateConstraint:self.cellTopBelowLabelToAvatarVerticalSpaceConstraint withConstant:customAttributes.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace];
    
    [self jsq_updateConstraint:self.messageBubbleTopLabelHeightConstraint
                  withConstant:customAttributes.messageBubbleTopLabelHeight];

    [self jsq_updateConstraint:self.cellBottomLabelHeightConstraint
                  withConstant:customAttributes.cellBottomLabelHeight];
    [self jsq_updateConstraint:self.cellBottomCountLabelHeightConstraint
                  withConstant:customAttributes.cellBottomCountLabelHeight];
    [self jsq_updateConstraint:self.cellBottomFailButtonHeightConstraint
                  withConstant:customAttributes.cellBottomFailButtonHeight];
    [self jsq_updateConstraint:self.systemNotificationImageViewHeightConstraint
                  withConstant:customAttributes.systemNotificationImageViewHeight];
    [self jsq_updateConstraint:self.gotoSystemNotificationButtonsContainerViewHeightConstraint
                  withConstant:customAttributes.gotoSystemNotificationButtonsContainerViewHeight];

    if ([self isKindOfClass:[JSQMessagesCollectionViewCellIncoming class]]) {
        self.avatarViewSize = customAttributes.incomingAvatarViewSize;
    }
    else if ([self isKindOfClass:[JSQMessagesCollectionViewCellOutgoing class]]) {
        self.avatarViewSize = customAttributes.outgoingAvatarViewSize;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
//    [super setHighlighted:highlighted];
//    self.messageBubbleImageView.highlighted = highlighted;
}

- (void)setSelected:(BOOL)selected
{
//    [super setSelected:selected];
//    self.avatarImageView.highlighted = selected;
//    self.messageBubbleImageView.highlighted = selected;
}

//  FIXME: radar 18326340
//         remove when fixed
//         hack for Xcode6 / iOS 8 SDK rendering bug that occurs on iOS 7.x
//         see issue #484
//         https://github.com/jessesquires/JSQMessagesViewController/issues/484
//
- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    if ([UIDevice jsq_isCurrentDeviceBeforeiOS8]) {
        self.contentView.frame = bounds;
    }
}

#pragma mark - Menu actions

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }

    return [super respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(anInvocation.selector)]) {
        __unsafe_unretained id sender;
        [anInvocation getArgument:&sender atIndex:0];
        [self.delegate messagesCollectionViewCell:self didPerformAction:anInvocation.selector withSender:sender];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(aSelector)]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }

    return [super methodSignatureForSelector:aSelector];
}

#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];

    self.cellTopLabel.backgroundColor = backgroundColor;
    self.messageBubbleTopLabel.backgroundColor = backgroundColor;
    self.cellBottomLabel.backgroundColor = backgroundColor;
    self.cellBottomCountLabel.backgroundColor = backgroundColor;

    self.messageBubbleImageView.backgroundColor = backgroundColor;
    self.avatarImageView.backgroundColor = backgroundColor;

    self.messageBubbleContainerView.backgroundColor = backgroundColor;
    self.avatarContainerView.backgroundColor = backgroundColor;
    
    self.systemNotificationImageView.backgroundColor = backgroundColor;
    self.gotoSystemNotificationButtonsContainerView.backgroundColor = backgroundColor;
    self.gotoSystemNotificationButtonsView.backgroundColor = backgroundColor;
    self.gotoSystemNotificationButtonsLineView.backgroundColor = backgroundColor;
}

- (void)setAvatarViewSize:(CGSize)avatarViewSize
{
    if (CGSizeEqualToSize(avatarViewSize, self.avatarViewSize)) {
        return;
    }

    [self jsq_updateConstraint:self.avatarContainerViewWidthConstraint withConstant:avatarViewSize.width];
    [self jsq_updateConstraint:self.avatarContainerViewHeightConstraint withConstant:avatarViewSize.height];
}

- (void)setTextViewFrameInsets:(UIEdgeInsets)textViewFrameInsets
{
    if (UIEdgeInsetsEqualToEdgeInsets(textViewFrameInsets, self.textViewFrameInsets)) {
        return;
    }

    [self jsq_updateConstraint:self.textViewTopVerticalSpaceConstraint withConstant:textViewFrameInsets.top];
    [self jsq_updateConstraint:self.textViewBottomVerticalSpaceConstraint withConstant:textViewFrameInsets.bottom];
    [self jsq_updateConstraint:self.textViewAvatarHorizontalSpaceConstraint withConstant:textViewFrameInsets.right];
    [self jsq_updateConstraint:self.textViewMarginHorizontalSpaceConstraint withConstant:textViewFrameInsets.left];
}

//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
//    // disable copy: to call this method and this should be called in JSQMessagesCellTextView.m aswell
//    // set self.textView.userInteractionEnabled = YES;
//    if (action == @selector(copy:)) {
//        return NO;
//    }
//    return [super canPerformAction:action withSender:sender];
//}

- (void)setMediaView:(UIView *)mediaView
{
    [self.messageBubbleImageView removeFromSuperview];
    [self.textView removeFromSuperview];
    [self.systemNotificationImageView removeFromSuperview];

    [self jsq_updateConstraint:self.bubbleContainerAvatarHorizontalSpaceConstraint withConstant:0.0f];

    [mediaView setTranslatesAutoresizingMaskIntoConstraints:NO];
    mediaView.frame = self.messageBubbleContainerView.bounds;

    [self.messageBubbleContainerView addSubview:mediaView];
    [self.messageBubbleContainerView jsq_pinAllEdgesOfSubview:mediaView];
    _mediaView = mediaView;

    //  because of cell re-use (and caching media views, if using built-in library media item)
    //  we may have dequeued a cell with a media view and add this one on top
    //  thus, remove any additional subviews hidden behind the new media view
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSUInteger i = 0; i < self.messageBubbleContainerView.subviews.count; i++) {
            if (self.messageBubbleContainerView.subviews[i] != _mediaView) {
                [self.messageBubbleContainerView.subviews[i] removeFromSuperview];
            }
        }
    });
}

#pragma mark - Getters

- (CGSize)avatarViewSize
{
    return CGSizeMake(self.avatarContainerViewWidthConstraint.constant,
                      self.avatarContainerViewHeightConstraint.constant);
}

- (UIEdgeInsets)textViewFrameInsets
{
    return UIEdgeInsetsMake(self.textViewTopVerticalSpaceConstraint.constant,
                            self.textViewMarginHorizontalSpaceConstraint.constant,
                            self.textViewBottomVerticalSpaceConstraint.constant,
                            self.textViewAvatarHorizontalSpaceConstraint.constant);
}

#pragma mark - Utilities

- (void)jsq_updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant
{
    if (constraint.constant == constant) {
        return;
    }

    constraint.constant = constant;
}

#pragma mark - Gesture recognizers

- (void)jsq_handleTapGesture:(UITapGestureRecognizer *)tap
{
    CGPoint touchPt = [tap locationInView:self];

    if (CGRectContainsPoint(self.avatarContainerView.frame, touchPt)) {
        [self.delegate messagesCollectionViewCellDidTapAvatar:self];
    }
    else if (CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt)) {
        [self.delegate messagesCollectionViewCellDidTapMessageBubble:self];
    }
    else if (CGRectContainsPoint(self.messageBubbleTopLabel.frame, touchPt)) {
        [self.delegate messagesCollectionViewCellDidTapMessageBubbleTopLabel:self];
    }
    else {
        [self.delegate messagesCollectionViewCellDidTapCell:self atPosition:touchPt];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchPt = [touch locationInView:self];

    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt);
    }
    
    return YES;
}

#pragma mark - Actions

- (void)failButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messagesCollectionViewCellDidTapFailButton:sender:)]) {
        [self.delegate messagesCollectionViewCellDidTapFailButton:self sender:sender];
    }
}

- (void)gotoSystemNotificationButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messagesCollectionViewCellDidTapGotoSystemNotificationButton:sender:)]) {
        [self.delegate messagesCollectionViewCellDidTapGotoSystemNotificationButton:self sender:sender];
    }
}

@end
