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

#import "JSQMessagesComposerTextView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSString+JSQMessages.h"


@implementation JSQMessagesComposerTextView

#pragma mark - Initialization

- (void)jsq_configureTextView
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    CGFloat cornerRadius = 4.0f;

    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 0.0f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = cornerRadius;

    self.scrollIndicatorInsets = UIEdgeInsetsMake(cornerRadius, 0.0f, cornerRadius, 0.0f);

    self.textContainerInset = UIEdgeInsetsMake(7.0f, 2.0f, 7.0f, 2.0f);
    self.contentInset = UIEdgeInsetsMake(1.0f, 0.0f, 1.0f, 0.0f);

    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.userInteractionEnabled = YES;

    self.font = [UIFont systemFontOfSize:14.0f];
    self.textColor = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentNatural;

    self.contentMode = UIViewContentModeRedraw;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeyDefault;

    self.text = nil;

    _placeHolder = nil;
    _placeHolderTextColor = [UIColor lightGrayColor];

    [self jsq_addTextViewNotificationObservers];
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self jsq_configureTextView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self jsq_configureTextView];
}

- (void)dealloc
{
    [self jsq_removeTextViewNotificationObservers];
    _placeHolder = nil;
    _placeHolderTextColor = nil;
}

#pragma mark - Composer text view

- (BOOL)hasText
{
    return ([[self.text jsq_stringByTrimingWhitespace] length] > 0);
}

#pragma mark - Setters

- (void)setPlaceHolder:(NSString *)placeHolder
{
    if ([placeHolder isEqualToString:_placeHolder]) {
        return;
    }

    _placeHolder = [placeHolder copy];
    [self setNeedsDisplay];
}

- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor
{
    if ([placeHolderTextColor isEqual:_placeHolderTextColor]) {
        return;
    }

    _placeHolderTextColor = placeHolderTextColor;
    [self setNeedsDisplay];
}

#pragma mark - UITextView overrides

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    [self setNeedsDisplay];
}

- (void)paste:(id)sender
{
    if (([[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] != NSOrderedAscending)) {
        if (!self.pasteDelegate || [self.pasteDelegate composerTextView:self shouldPasteWithSender:sender]) {
            [super paste:sender];
        }
    } else {
        if ([[UIPasteboard generalPasteboard].string isKindOfClass:[NSString class]]) {
            [super paste:sender];
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    [UIMenuController sharedMenuController].menuItems = nil;
    
    if (!self.useTextCopy) {
        if (action == @selector(copy:) || action == @selector(cut:)) {
            return NO;
        }
    }
    
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if ([self.text length] == 0 && self.placeHolder) {
        [self.placeHolderTextColor set];

        [self.placeHolder drawInRect:CGRectInset(rect, 7.0f, 8.0f)
                      withAttributes:[self jsq_placeholderTextAttributes]];
    }
}

#pragma mark - Notifications

- (void)jsq_addTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];
}

- (void)jsq_removeTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidChangeNotification
                                                  object:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidBeginEditingNotification
                                                  object:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:self];
}

- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification
{
    [self setNeedsDisplay];
}

#pragma mark - Utilities

- (NSDictionary *)jsq_placeholderTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = self.textAlignment;

    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.placeHolderTextColor,
              NSParagraphStyleAttributeName : paragraphStyle };
}


// touch input field keyboard
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    [super addGestureRecognizer:gestureRecognizer];
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tgr = (UITapGestureRecognizer *)gestureRecognizer;
        if ([tgr numberOfTapsRequired] == 1 &&
            [tgr numberOfTouchesRequired] == 1) {
            [tgr addTarget:self action:@selector(_handleOneFingerTap:)];
        }
    }
}

- (void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tgr = (UITapGestureRecognizer *)gestureRecognizer;
        if ([tgr numberOfTapsRequired] == 1 &&
            [tgr numberOfTouchesRequired] == 1) {
            [tgr removeTarget:self action:@selector(_handleOneFingerTap:)];
        }
    }
    [super removeGestureRecognizer:gestureRecognizer];
}

- (void)_handleOneFingerTap:(UITapGestureRecognizer *)tgr
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tgr forKey:@"UITapGestureRecognizer"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jsqComposerTextViewOneFingerTapNotification" object:self userInfo:userInfo];
}

#pragma mark - Interface Methods (Custom)

- (void)updateReturnKeySettingWithKeyboardOption:(BOOL)useSendKey {
    if (useSendKey) {
        self.returnKeyType = UIReturnKeySend;
    } else {
        self.returnKeyType = UIReturnKeyDefault;
    }
}

#pragma mark - UIMenuController

- (BOOL)canBecomeFirstResponder
{
    return [super canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [super becomeFirstResponder];
}

@end
