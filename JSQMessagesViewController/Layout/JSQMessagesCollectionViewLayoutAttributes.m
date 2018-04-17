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

#import "JSQMessagesCollectionViewLayoutAttributes.h"

@implementation JSQMessagesCollectionViewLayoutAttributes

#pragma mark - Lifecycle

- (void)dealloc
{
    _messageBubbleFont = nil;
}

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        _messageBubbleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _messageBubbleContainerViewWidth = 320.0f;
    }
    return self;
}

#pragma mark - Setters

- (void)setMessageBubbleFont:(UIFont *)messageBubbleFont
{
    NSParameterAssert(messageBubbleFont != nil);
    _messageBubbleFont = messageBubbleFont;
}

- (void)setMessageBubbleContainerViewWidth:(CGFloat)messageBubbleContainerViewWidth
{
    NSParameterAssert(messageBubbleContainerViewWidth > 0.0f);
    _messageBubbleContainerViewWidth = ceilf(messageBubbleContainerViewWidth);
}

- (void)setIncomingAvatarViewSize:(CGSize)incomingAvatarViewSize
{
    NSParameterAssert(incomingAvatarViewSize.width >= 0.0f && incomingAvatarViewSize.height >= 0.0f);
    _incomingAvatarViewSize = [self jsq_correctedAvatarSizeFromSize:incomingAvatarViewSize];
}

- (void)setOutgoingAvatarViewSize:(CGSize)outgoingAvatarViewSize
{
    NSParameterAssert(outgoingAvatarViewSize.width >= 0.0f && outgoingAvatarViewSize.height >= 0.0f);
    _outgoingAvatarViewSize = [self jsq_correctedAvatarSizeFromSize:outgoingAvatarViewSize];
}

- (void)setCellTopLabelHeight:(CGFloat)cellTopLabelHeight
{
    NSParameterAssert(cellTopLabelHeight >= 0.0f);
    _cellTopLabelHeight = [self jsq_correctedLabelHeightForHeight:cellTopLabelHeight];
    _cellTopLabelToCellTopBelowLabelVerticalSpace = (cellTopLabelHeight > 0.0f) ? kJSQMessagesLabelVerticalSpaceDefault : 0.0f;
}

- (void)setCellTopBelowLabelHeight:(CGFloat)cellTopBelowLabelHeight
{
    NSParameterAssert(cellTopBelowLabelHeight >= 0.0f);
    _cellTopBelowLabelHeight = [self jsq_correctedLabelHeightForHeight:cellTopBelowLabelHeight];
    _cellTopBelowLabelToMessageBubbleToplabelVerticalSpace = (cellTopBelowLabelHeight > 0.0f) ? kJSQMessagesLabelVerticalSpaceDefault : 0.0f;
}

- (void)setMessageBubbleTopLabelHeight:(CGFloat)messageBubbleTopLabelHeight
{
    NSParameterAssert(messageBubbleTopLabelHeight >= 0.0f);
    _messageBubbleTopLabelHeight = [self jsq_correctedLabelHeightForHeight:messageBubbleTopLabelHeight];
}

- (void)setCellBottomLabelHeight:(CGFloat)cellBottomLabelHeight
{
    NSParameterAssert(cellBottomLabelHeight >= 0.0f);
    _cellBottomLabelHeight = [self jsq_correctedLabelHeightForHeight:cellBottomLabelHeight];
}

- (void)setCellBottomCountLabelHeight:(CGFloat)cellBottomCountLabelHeight
{
    NSParameterAssert(cellBottomCountLabelHeight >= 0.0f);
    _cellBottomCountLabelHeight = [self jsq_correctedLabelHeightForHeight:cellBottomCountLabelHeight];
}

- (void)setCellBottomFailButtonHeight:(CGFloat)cellBottomFailButtonHeight
{
    NSParameterAssert(cellBottomFailButtonHeight >= 0.0f);
    _cellBottomFailButtonHeight = [self jsq_correctedLabelHeightForHeight:cellBottomFailButtonHeight];
}

- (void)setSystemNotificationImageViewHeight:(CGFloat)systemNotificationImageViewHeight
{
    NSParameterAssert(systemNotificationImageViewHeight >= 0.0f);
    _systemNotificationImageViewHeight = [self jsq_correctedLabelHeightForHeight:systemNotificationImageViewHeight];
}

- (void)setGotoSystemNotificationButtonsContainerViewHeight:(CGFloat)gotoSystemNotificationButtonsContainerViewHeight
{
    NSParameterAssert(gotoSystemNotificationButtonsContainerViewHeight >= 0.0f);
    _gotoSystemNotificationButtonsContainerViewHeight = [self jsq_correctedLabelHeightForHeight:gotoSystemNotificationButtonsContainerViewHeight];
}

#pragma mark - Utilities

- (CGSize)jsq_correctedAvatarSizeFromSize:(CGSize)size
{
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

- (CGFloat)jsq_correctedLabelHeightForHeight:(CGFloat)height
{
    return ceilf(height);
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (self.representedElementCategory == UICollectionElementCategoryCell) {
        JSQMessagesCollectionViewLayoutAttributes *layoutAttributes = (JSQMessagesCollectionViewLayoutAttributes *)object;
        
        if (![layoutAttributes.messageBubbleFont isEqual:self.messageBubbleFont]
            || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewFrameInsets, self.textViewFrameInsets)
            || !UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.textViewTextContainerInsets, self.textViewTextContainerInsets)
            || !CGSizeEqualToSize(layoutAttributes.incomingAvatarViewSize, self.incomingAvatarViewSize)
            || !CGSizeEqualToSize(layoutAttributes.outgoingAvatarViewSize, self.outgoingAvatarViewSize)
            || (int)layoutAttributes.messageBubbleContainerViewWidth != (int)self.messageBubbleContainerViewWidth
            || (int)layoutAttributes.cellTopLabelHeight != (int)self.cellTopLabelHeight
            || (int)layoutAttributes.cellTopBelowLabelHeight != (int)self.cellTopBelowLabelHeight
            || (int)layoutAttributes.cellTopLabelToCellTopBelowLabelVerticalSpace != (int)self.cellTopLabelToCellTopBelowLabelVerticalSpace
            || (int)layoutAttributes.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace != (int)self.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace
            || (int)layoutAttributes.messageBubbleTopLabelHeight != (int)self.messageBubbleTopLabelHeight
            || (int)layoutAttributes.cellBottomLabelHeight != (int)self.cellBottomLabelHeight
            || (int)layoutAttributes.cellBottomCountLabelHeight != (int)self.cellBottomCountLabelHeight
            || (int)layoutAttributes.cellBottomFailButtonHeight != (int)self.cellBottomFailButtonHeight
            || (int)layoutAttributes.systemNotificationImageViewHeight != (int)self.systemNotificationImageViewHeight
            || (int)layoutAttributes.gotoSystemNotificationButtonsContainerViewHeight != (int)self.gotoSystemNotificationButtonsContainerViewHeight) {
            return NO;
        }
    }
    
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [self.indexPath hash];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    JSQMessagesCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    
    if (copy.representedElementCategory != UICollectionElementCategoryCell) {
        return copy;
    }
    
    copy.messageBubbleFont = self.messageBubbleFont;
    copy.messageBubbleContainerViewWidth = self.messageBubbleContainerViewWidth;
    copy.textViewFrameInsets = self.textViewFrameInsets;
    copy.textViewTextContainerInsets = self.textViewTextContainerInsets;
    copy.incomingAvatarViewSize = self.incomingAvatarViewSize;
    copy.outgoingAvatarViewSize = self.outgoingAvatarViewSize;
    copy.cellTopLabelHeight = self.cellTopLabelHeight;
    copy.cellTopBelowLabelHeight = self.cellTopBelowLabelHeight;
    copy.cellTopLabelToCellTopBelowLabelVerticalSpace = self.cellTopLabelToCellTopBelowLabelVerticalSpace;
    copy.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace = self.cellTopBelowLabelToMessageBubbleToplabelVerticalSpace;
    copy.messageBubbleTopLabelHeight = self.messageBubbleTopLabelHeight;
    copy.cellBottomLabelHeight = self.cellBottomLabelHeight;
    copy.cellBottomCountLabelHeight = self.cellBottomCountLabelHeight;
    copy.cellBottomFailButtonHeight = self.cellBottomFailButtonHeight;
    copy.systemNotificationImageViewHeight = self.systemNotificationImageViewHeight;
    copy.gotoSystemNotificationButtonsContainerViewHeight = self.gotoSystemNotificationButtonsContainerViewHeight;
    
    return copy;
}

@end
