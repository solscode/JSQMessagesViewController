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

#import "DemoMessagesViewController.h"

@implementation DemoMessagesViewController

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"JSQMessages";
    
    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = kJSQDemoAvatarIdSquires;
    self.senderDisplayName = kJSQDemoAvatarDisplayNameSquires;
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    /**
     *  Load up our fake data for the demo
     */
    self.demoData = [[DemoModelData alloc] init];
    
    
    /**
     *  You can set custom avatar sizes
     */
    if (![NSUserDefaults incomingAvatarSetting]) {
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    }
    
    if (![NSUserDefaults outgoingAvatarSetting]) {
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
    
    self.showLoadEarlierMessagesHeader = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage jsq_defaultTypingIndicatorImage]
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(receiveMessagePressed:)];

    /**
     *  Register custom menu actions for cells.
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];

	
    /**
     *  OPT-IN: allow cells to be deleted
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];

    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */

    /**
     *  Set a maximum height for the input toolbar
     *
     *  self.inputToolbar.maximumHeight = 150;
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.delegateModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                              target:self
                                                                                              action:@selector(closePressed:)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = [NSUserDefaults springinessSetting];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender {
    if ([USE_RESEND_AUTO isEqualToString:@"NO"] || [USE_RESEND_PENDING_MESSAGES isEqualToString:@"NO"]) {
        if (![CommonUtils isSocketServerReachable]) {
            if (OS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
                [CommonUtils showAlertViewController:self withMessage:talkLocalized(@"Error.NetworkNotReachable") checkDuplication:YES];
            } else {
                [CommonUtils showAlertWithMessage:talkLocalized(@"Error.NetworkNotReachable") checkDuplication:YES];
            }
            return;
        }
        if (!([_socket isConnected] && self.isJoined)) {
            if (OS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
                [CommonUtils showAlertViewController:self withMessage:talkLocalized(@"Error.Socket.NotJoined") checkDuplication:YES];
            } else {
                [CommonUtils showAlertWithMessage:talkLocalized(@"Error.Socket.NotJoined") checkDuplication:YES];
            }
            if (!self.isSocketConnecting) {
                [self socketConnect];
            }
            return;
        }
    }
    if (!([_socket isConnected] && self.isJoined) && [CommonUtils isSocketServerReachable]) {
        if (!self.isSocketConnecting) {
            [self socketConnect];
        }
    }
    
    if (!([self.currentChat.userCount integerValue] > 0)) {
        if (OS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            [CommonUtils showAlertViewController:self withMessage:talkLocalized(@"Alert.ChatMemberNone") checkDuplication:YES];
        } else {
            [CommonUtils showAlertWithMessage:talkLocalized(@"Alert.ChatMemberNone") checkDuplication:YES];
        }
        return;
    }
    if (self.isStickerPreviewShow) {
        NSString *messageType = TYPE_MESSAGE_STICKER;
        NSString *messageText = [NSString stringWithFormat:@"%@|%@", self.stickerCategory, self.stickerIndex];
        [self removeSticker];
        [self sendMessageWithText:messageText type:messageType];
    }
    if ([self.inputToolbar.contentView.textView hasText]) {
        NSString *messageType = TYPE_MESSAGE_TEXT;
        NSString *messageText = [self.inputToolbar.contentView.textView.text copy];
        [self sendMessageWithText:messageText type:messageType];
    }
    [self clearTextView];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    if (self.isStickerPadShow) {
        self.keyboardController.showStickerPadWhenHardwareKeyboard = NO;
        [self hideStickerPad];
        if (self.keyboardController.isUsingHardwareKeyboard) {
            [self resignInputToolbar];
        }
    } else {
        self.keyboardController.showStickerPadWhenHardwareKeyboard = YES;
        if (![self.inputToolbar.contentView.textView isFirstResponder]) {
            [self.inputToolbar.contentView.textView becomeFirstResponder];
        }
        [self showStickerPad];
    }
}

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressAddBarButton:(UIButton *)sender {
    [self resignInputToolbar];
    
    [self showAddBarButtonMenuSheet];
}

- (BOOL)jsq_isMenuVisible {
    return self.selectedIndexPathForMenu != nil && [[UIMenuController sharedMenuController] isMenuVisible];
}

- (void)reloadCollectionView:(BOOL)reload toBottom:(BOOL)toBottom animated:(BOOL)animated {
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        self.showLoadEarlierMessagesHeader = NO;
    }
    if (reload) {
        [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
        [self.collectionView reloadData];
    }
    if (toBottom && ![self jsq_isMenuVisible]) {
        [self scrollToBottomAnimated:animated];
    }
}

- (void)scrolledToBottom {
    if ([USE_CHATROOM_TOBOTTOM_BUTTON isEqualToString:@"YES"]) {
        [self showGotoBottomView:NO];
    }
    self.isCurrentPositionBottom = YES;
    self.gotoBottomWhenTextViewEditing = [self gotoBottomOnReload];
}

- (void)textViewHeightChanged {
    if (self.stickerPreview) {
        CGRect previewFrame = self.stickerPreview.frame;
        previewFrame.origin.y = self.inputToolbar.frame.origin.y - previewFrame.size.height;
        self.stickerPreview.frame = previewFrame;
    }
}

- (void)willRotate {
    if (![self isContentTooSmall]) {
        CGFloat viewHeight = [self visibleViewPartHeight];
        self.currentBottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y - viewHeight;
    }
    [self setChatRoomTitle:self.currentChat isPortrait:![self isPortrait]];
    
    [self.stickerPadView removeFromSuperview];
    self.stickerPadView = nil;
}

- (void)didRotate {
    if (![self isContentTooSmall]) {
        CGFloat viewHeight = [self visibleViewPartHeight];
        CGFloat newBottomOffset = self.collectionView.contentSize.height - self.currentBottomOffset - viewHeight;
        [self.collectionView setContentOffset:CGPointMake(0, newBottomOffset) animated:NO];
    }
}

- (void)willShowJsqMenuAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *menuItems = [NSMutableArray array];
    
    if (self.fetchedResultsController && self.fetchedResultsController.fetchedObjects.count > 0) {
        Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (message) {
            if ([USE_RESEND_PENDING_MESSAGES isEqualToString:@"YES"]) {
                if ([self needShowMessageFailButtonForMessage:message]) {
                    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Common.Delete") action:@selector(deleteChatMessage:)]];
                    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.Resend") action:@selector(resendChatMessage:)]];
                }
            }
            
            if ([USE_CHATROOM_FORWARD_MESSAGE isEqualToString:@"YES"]) {
                if (![self needShowMessageFailButtonForMessage:message] && ![self isSecureImageForMessage:message]) {
                    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.Forward") action:@selector(forwardChatMessage:)]];
                }
            }
            
            if ([USE_CHATROOM_REUSE_MESSAGE isEqualToString:@"YES"]) {
                if (![self needShowMessageFailButtonForMessage:message] && ![self isTypeChatroomSystemNotificationWithChatNo:self.currentChat.chatNo]) {
                    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.Reuse") action:@selector(reuseChatMessage:)]];
                }
            }
            
            if ([USE_CHATROOM_NOTICE isEqualToString:@"YES"]) {
                if (![self needShowMessageFailButtonForMessage:message]) {
                    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.ChatNotice") action:@selector(postNoticeWithChatMessage:)]];
                }
            }
            
            if (![self needShowMessageFailButtonForMessage:message]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.AutoText") action:@selector(autoTextChatMessage:)]];
            }
            
            if (![self needShowMessageFailButtonForMessage:message] && ![self isMessageStoredOnServerExpiredOnDaysFromDate:message.messageDate]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:talkLocalized(@"Menu.UnreadUser") action:@selector(getUnreadUserCountWithChatMessage:)]];
            }
        }
    }
    
    [UIMenuController sharedMenuController].menuItems = [NSArray arrayWithArray:menuItems];
}

- (void)willHideJsqMenu {
    if ([USE_CHATROOM_NOTICE isEqualToString:@"YES"] || [USE_RESEND_PENDING_MESSAGES isEqualToString:@"YES"]) {
        [UIMenuController sharedMenuController].menuItems = nil;
    }
}

- (void)textViewDidChange {
    if (self.useTypingIndicator) {
        if ([self.inputToolbar.contentView.textView hasText]) {
            if ([self.typingIdleTimer isValid]) {
                [self.typingIdleTimer invalidate];
                self.typingIdleTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(sendTypingEnd) userInfo:nil repeats:NO];
            } else {
                [self sendTypingStart];
                self.typingIdleTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(sendTypingEnd) userInfo:nil repeats:NO];
            }
        } else {
            [self sendTypingEnd];
        }
    }
}

- (void)textViewDidEndEditing {
    
}

- (void)textViewWillLimitLengthWithShowAllowedLengthAlert:(BOOL)showAlert {
    if ([USE_CHATROOM_TEXT_LIMIT isEqualToString:@"YES"]) {
        if (self.inputToolbar.contentView.textView.text.length > self.allowedTextLength) {
            if ([CommonUtils stringContainsEmoji:[self.inputToolbar.contentView.textView.text substringWithRange:NSMakeRange(self.allowedTextLength -1, 2)]]) {
                self.inputToolbar.contentView.textView.text = [self.inputToolbar.contentView.textView.text substringToIndex:self.allowedTextLength - 1];
            } else {
                self.inputToolbar.contentView.textView.text = [self.inputToolbar.contentView.textView.text substringToIndex:self.allowedTextLength];
            }
            NSString *message = [talkLocalized(@"Alert.TextLength.NotAllowed") stringByAppendingString:[NSString stringWithFormat:@" %ld %@", (long)self.allowedTextLength, talkLocalized(@"Alert.AllowedTextLength")]];
            
            if (showAlert) {
                talkDispatchOnMainThread(^{
                    [UIAlertController showAlertInViewController:self withTitle:nil message:message cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:[NSArray arrayWithObject:talkLocalized(@"Common.OK")] tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex){
                    }];
                });
            }
        }
    }
}

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
{
    /**
     *  Display custom menu actions for cells.
     */
    UIMenuController *menu = [notification object];
    menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action" action:@selector(customAction:)] ];
}



#pragma mark - Testing

- (void)pushMainViewController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateInitialViewController];
    [self.navigationController pushViewController:nc.topViewController animated:YES];
}


#pragma mark - Actions

- (void)receiveMessagePressed:(UIBarButtonItem *)sender
{
    /**
     *  DEMO ONLY
     *
     *  The following is simply to simulate received messages for the demo.
     *  Do not actually do this.
     */
    
    
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    /**
     *  Copy last sent message, this will be the new "received" message
     */
    JSQMessage *copyMessage = [[self.demoData.messages lastObject] copy];
    
    if (!copyMessage) {
        copyMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdJobs
                                          displayName:kJSQDemoAvatarDisplayNameJobs
                                                 text:@"First received!"];
    }
    
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray *userIds = [[self.demoData.users allKeys] mutableCopy];
        [userIds removeObject:self.senderId];
        NSString *randomUserId = userIds[arc4random_uniform((int)[userIds count])];
        
        JSQMessage *newMessage = nil;
        id<JSQMessageMediaData> newMediaData = nil;
        id newMediaAttachmentCopy = nil;
        
        if (copyMessage.isMediaMessage) {
            /**
             *  Last message was a media message
             */
            id<JSQMessageMediaData> copyMediaData = copyMessage.media;
            
            if ([copyMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                JSQPhotoMediaItem *photoItemCopy = [((JSQPhotoMediaItem *)copyMediaData) copy];
                photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItemCopy.image.CGImage];
                
                /**
                 *  Set image to nil to simulate "downloading" the image
                 *  and show the placeholder view
                 */
                photoItemCopy.image = nil;
                
                newMediaData = photoItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *locationItemCopy = [((JSQLocationMediaItem *)copyMediaData) copy];
                locationItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [locationItemCopy.location copy];
                
                /**
                 *  Set location to nil to simulate "downloading" the location data
                 */
                locationItemCopy.location = nil;
                
                newMediaData = locationItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)copyMediaData) copy];
                videoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [videoItemCopy.fileURL copy];
                
                /**
                 *  Reset video item to simulate "downloading" the video
                 */
                videoItemCopy.fileURL = nil;
                videoItemCopy.isReadyToPlay = NO;
                
                newMediaData = videoItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQAudioMediaItem class]]) {
                JSQAudioMediaItem *audioItemCopy = [((JSQAudioMediaItem *)copyMediaData) copy];
                audioItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [audioItemCopy.audioData copy];
                
                /**
                 *  Reset audio item to simulate "downloading" the audio
                 */
                audioItemCopy.audioData = nil;
                
                newMediaData = audioItemCopy;
            }
            else {
                NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
            }
            
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:self.demoData.users[randomUserId]
                                                   media:newMediaData];
        }
        else {
            /**
             *  Last message was a text message
             */
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:self.demoData.users[randomUserId]
                                                    text:copyMessage.text];
        }
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        [self.demoData.messages addObject:newMessage];
        [self finishReceivingMessageAnimated:YES];
        
        
        if (newMessage.isMediaMessage) {
            /**
             *  Simulate "downloading" media
             */
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Media is "finished downloading", re-display visible cells
                 *
                 *  If media cell is not visible, the next time it is dequeued the view controller will display its new attachment data
                 *
                 *  Reload the specific item, or simply call `reloadData`
                 */
                
                if ([newMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                    ((JSQPhotoMediaItem *)newMediaData).image = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                    [((JSQLocationMediaItem *)newMediaData)setLocation:newMediaAttachmentCopy withCompletionHandler:^{
                        [self.collectionView reloadData];
                    }];
                }
                else if ([newMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                    ((JSQVideoMediaItem *)newMediaData).fileURL = newMediaAttachmentCopy;
                    ((JSQVideoMediaItem *)newMediaData).isReadyToPlay = YES;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQAudioMediaItem class]]) {
                    ((JSQAudioMediaItem *)newMediaData).audioData = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else {
                    NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
                }
                
            });
        }
        
    });
}

- (void)closePressed:(UIBarButtonItem *)sender
{
    [self.delegateModal didDismissJSQDemoViewController:self];
}




#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    [self.demoData.messages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", @"Send audio", nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            [self.demoData addPhotoMediaMessage];
            break;
            
        case 1:
        {
            __weak UICollectionView *weakView = self.collectionView;
            
            [self.demoData addLocationMediaMessageCompletion:^{
                [weakView reloadData];
            }];
        }
            break;
            
        case 2:
            [self.demoData addVideoMediaMessage];
            break;
            
        case 3:
            [self.demoData addAudioMediaMessage];
            break;
    }
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [self finishSendingMessageAnimated:YES];
}



- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath loadDataIfNeeded:(BOOL)loadDataIfNeeded {
    return [self jsqMessageAtIndexPath:indexPath loadDataIfNeeded:loadDataIfNeeded];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[self avatarImageOfSenderWithId:message.senderId] diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    
    return avatarImage;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if ([USE_CHATROOM_TOBOTTOM_BUTTON isEqualToString:@"YES"] && self.showLastReadCellTopBelowLabelText  && indexPath.item > 0) {
        Message *previousChatMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section]];
        NSInteger previousChatMessageSeq = previousChatMessage.messageSeq ? [previousChatMessage.messageSeq integerValue] : -1;
        if (self.lastReadMessageSeq > 0 && self.lastReadMessageSeq == previousChatMessageSeq) {
            return [[NSAttributedString alloc] initWithString:talkLocalized(@"Chat.LastReadHere")];
        }
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopBelowLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if (message.messageDate && indexPath.item >= 0) {
        if (indexPath.item == 0) {
            return [[NSAttributedString alloc] initWithString:[CommonUtils fullDayStringFromDate:message.messageDate]];
        } else {
            Message *previousMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section]];
            if (previousMessage.messageDate && [CommonUtils daysFromDate:previousMessage.messageDate toDate:message.messageDate] > 0) {
                return [[NSAttributedString alloc] initWithString:[CommonUtils fullDayStringFromDate:message.messageDate]];
            }
        }
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    UserDao *userMainDao = (UserDao *)[[ResourceManager sharedManger] mainDao:[UserDao class]];
    User *user = [userMainDao userWithUserId:message.senderId];
    NSAttributedString *nameLabel = [CommonUtils attributedStringWithString:[NSString stringWithFormat:@"%@ ", user.userName ?: message.senderName]
                                                                       font:[UIFont systemFontOfSize:13.0f]
                                                                      color:RGB(36, 36, 36)
                                                            appendingString:nil //user.positionName
                                                                      aFont:[UIFont systemFontOfSize:12.0f]
                                                                     aColor:RGB(87, 87, 87) aOffset:0.0f];
    return nameLabel;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForGotoSystemNotificationTitledButtonAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType] && [self hasLinkUrlAndSystemIdForSystemNotificationMessage:message]) {
        NSAttributedString *linkTitleString = [CommonUtils attributedStringWithString:[self linkTitleForSystemNotificationMessage:message]
                                                                             font:[UIFont systemFontOfSize:13.0f]
                                                                            color:RGB(121, 121, 121)
                                                                  appendingString:nil
                                                                            aFont:[UIFont systemFontOfSize:12.0f]
                                                                           aColor:RGB(87, 87, 87) aOffset:0.0f];
        return linkTitleString;
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    NSAttributedString *timeString = [[NSAttributedString alloc] initWithString:(message.messageDate ? [CommonUtils timeStringFromDate:message.messageDate] : @"-")];
    
    return timeString;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomCountLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    NSMutableAttributedString *countString = nil;
    
    if ([self.currentChat.groupYN boolValue] || ([self.senderId isEqualToString:message.senderId])) {
        Message *msg = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if ([USE_RESEND_PENDING_MESSAGES isEqualToString:@"YES"] && [msg.outgoingYN boolValue]) {
            if ([STATUS_MESSAGE_PENDING isEqualToString:msg.sendingStatus] || [STATUS_MESSAGE_RESENT isEqualToString:msg.sendingStatus]) {
                return [[NSAttributedString alloc] initWithString:@"➢"];
            }
        }
        
        if (![self isTypeChatroomLiteWithChatNo:self.currentChat.chatNo]) {
            NSInteger unreadUserCount = [msg.unreadUserCount integerValue];
            if (unreadUserCount > 0) {
                if (unreadUserCount > [self.currentChat.userCount integerValue] && [self.currentChat.userCount integerValue] > 0) {
                    unreadUserCount = [self.currentChat.userCount integerValue];
                }
                countString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)unreadUserCount]];
                [countString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.524 alpha:1.000] range:NSMakeRange(0, countString.length)];
            }
        }
    }
    
    return countString;
}

#pragma mark - UICollectionView Delegates

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    cell.textView.textColor = [UIColor blackColor];
    
    Message *message = [self messageAtIndexPath:indexPath];
    
    cell.cellBottomLabel.hidden = [self isNotifyMessage:message];
    cell.cellBottomCountLabel.hidden = [self isNotifyMessage:message];
    cell.cellTopLabel.layer.cornerRadius = 12;
    cell.cellTopLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.cellTopBelowLabel.layer.cornerRadius = 12;
    cell.cellTopBelowLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.messageBubbleTopLabel.font = [UIFont systemFontOfSize:13.0f];
    
    if ([self isTypeChatroomLiteWithChatNo:self.currentChat.chatNo]) {
        cell.backgroundColor = RGBCollectionViewBackgroundForChatroomLite;
        cell.cellTopLabel.backgroundColor = RGBNotifyMessagesBackgroundForChatroomLite;
        cell.cellTopLabel.textColor = RGBNotifyMessagesTextForChatroomLite;
        cell.cellTopBelowLabel.backgroundColor = RGBNotifyMessagesBackgroundForChatroomLite;
        cell.cellTopBelowLabel.textColor = RGBNotifyMessagesTextForChatroomLite;
        cell.cellBottomCountLabel.backgroundColor = RGBCollectionViewBackgroundForChatroomLite;
        cell.gotoSystemNotificationButtonsView.backgroundColor = [message.outgoingYN boolValue] ? RGBOutgoingMessagesBubbleImageForChatroomLite : RGBIncomingMessagesBubbleImageForChatroomLite;
        cell.gotoSystemNotificationButtonsLineView.backgroundColor = RGBCollectionViewBackgroundForChatroomLite;
    } else {
        cell.backgroundColor = RGBCollectionViewBackgroundForChatroomRegular;
        cell.cellTopLabel.backgroundColor = RGBNotifyMessagesTextForChatroomRegular;
        cell.cellTopLabel.textColor = RGBNotifyMessagesBackgroundForChatroomRegular;
        cell.cellTopBelowLabel.backgroundColor = RGBNotifyMessagesTextForChatroomRegular;
        cell.cellTopBelowLabel.textColor = RGBNotifyMessagesBackgroundForChatroomRegular;
        cell.cellBottomCountLabel.backgroundColor = RGBCollectionViewBackgroundForChatroomRegular;
        cell.gotoSystemNotificationButtonsView.backgroundColor = [message.outgoingYN boolValue] ? RGBOutgoingMessagesBubbleImageForChatroomRegular : RGBIncomingMessagesBubbleImageForChatroomRegular;
        cell.gotoSystemNotificationButtonsLineView.backgroundColor = RGBCollectionViewBackgroundForChatroomRegular;
    }
    
    cell.cellBottomLabel.font = [UIFont systemFontOfSize:10.0f];
    cell.cellBottomLabel.textColor = RGB(164, 164, 164);
    cell.cellBottomCountLabel.font = [UIFont systemFontOfSize:9.0f];
    cell.cellBottomCountLabel.textColor = RGB(60, 142, 230);
    cell.gotoSystemNotificationTitledButton.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    cell.gotoSystemNotificationTitledButton.titleLabel.numberOfLines = 2;
    [cell.gotoSystemNotificationTitledButton setTitleColor:RGB(121, 121, 121) forState:UIControlStateNormal];
    
    NSDictionary *chatFontSizeInfo = [SharedData getChatFontSizeInfo];
    CGFloat chatFontSize = SIZE_CHAT_FONT_DEFAULT;
    if (chatFontSizeInfo && chatFontSizeInfo[@"size"] && [chatFontSizeInfo[@"size"] floatValue] >= 12.0f) { // minimum size
        chatFontSize = [chatFontSizeInfo[@"size"] floatValue];
    }
    
    UIFont *chatFont = [UIFont systemFontOfSize:chatFontSize];
    
    if ([TYPE_MESSAGE_TEXT isEqualToString:message.messageType]) {
        if (self.isSearching) {
            cell.textView.attributedText = cell.textView.text ? [[NSAttributedString alloc] initWithAttributedString:[self getSearchKeywordColored:cell.textView.text isCurrentPath:[self.searchingIndexPath isEqual:indexPath] chatFont:chatFont]] : nil;
        } else {
            cell.textView.attributedText = cell.textView.text ? [[NSAttributedString alloc] initWithString:cell.textView.text attributes:@{NSBackgroundColorAttributeName : [UIColor clearColor], NSFontAttributeName:chatFont}] : nil;
        }
        
        cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName : cell.textView.textColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)};
    } else if ([USE_CHATROOM_SHOW_PHOTO_MESSAGE isEqualToString:@"YES"] && [TYPE_MESSAGE_IMAGE isEqualToString:message.messageType]) {
        JSQMessagesMediaView *mediaView = nil;
        UIView *cellMediaView = [cell mediaView];
        
        if (cellMediaView && [cellMediaView isKindOfClass:[JSQMessagesMediaView class]]) {
            mediaView = (JSQMessagesMediaView *)cellMediaView;
            
            if (mediaView.isPlaceholderView) {
                NSURL *imageThumbUrl = [[ChatDataManager sharedManager] fileUrlWithMessage:message fileType:FILE_TYPE_IMAGE imageSizetype:IMAGE_SIZE_TYPE_THUMB chat:self.currentChat];
                [mediaView.imageView setLocalImageWithURL:imageThumbUrl placeholderImage:nil rootPath:[PATH_CACHE_ROOT stringByAppendingPathComponent:self.currentChat.roomId] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    if (image && CGSizeGreaterThanZero(image.size)) {
                        mediaView.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    }
                } failure:nil progress:nil];
            }
            
            id transfer = message.messageLocalId ? [[FileTransferManager sharedManger].transfersInProgress objectForKey:message.messageLocalId][@"task"] : nil;
            if (transfer) {
                if ([[FileTransferManager sharedManger].transfersInProgress objectForKey:message.messageLocalId]) {
                    UAProgressView *progressView = nil;
                    
                    UIView *centerItemView = mediaView.centerItemView;
                    if (centerItemView && [centerItemView isKindOfClass:[UAProgressView class]]) {
                        progressView = (UAProgressView *)centerItemView;
                    } else {
                        progressView = [CommonUtils circularProgressViewWithMediaViewSize:mediaView.imageView.frame.size];
                    }
                    [mediaView setCenterItem:progressView];
                    mediaView.userInteractionEnabled = YES;
                    
                    [CommonUtils setTransferToProgressView:progressView transfer:transfer transferId:message.messageLocalId outgoingYN:[message.outgoingYN boolValue] selectionBlock:^(UAProgressView *currentProgressView) {
                        currentProgressView.hidden = YES;
                        if ([[FileTransferManager sharedManger].transfersInProgress objectForKey:message.messageLocalId]) {
                            [[[FileTransferManager sharedManger].transfersInProgress objectForKey:message.messageLocalId][@"task"] performSelector:@selector(cancel)];
                            [[FileTransferManager sharedManger].transfersInProgress removeObjectForKey:message.messageLocalId];
                        }
                    }];
                }
            }
        }
    } else if ([USE_CHATROOM_SHOW_FILE_MESSAGE isEqualToString:@"YES"] && [TYPE_MESSAGE_FILE isEqualToString:message.messageType]) {
        NSMutableAttributedString *messageString = [[NSMutableAttributedString alloc] initWithString:cell.textView.text];
        NSUInteger attributedStringLocation = [cell.textView.text rangeOfString:@"\n\n"].location;
        NSUInteger attributedStringLength = cell.textView.text.length - attributedStringLocation;
        [messageString addAttributes:@{NSFontAttributeName:chatFont, NSForegroundColorAttributeName:[UIColor blackColor]} range:NSMakeRange(0, cell.textView.text.length - attributedStringLength)];
        [messageString addAttributes:@{NSFontAttributeName:chatFont, NSForegroundColorAttributeName:RGB(57, 57, 57)} range:NSMakeRange(attributedStringLocation, attributedStringLength)];
        cell.textView.attributedText = messageString;
        cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName : cell.textView.textColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)};
    } else if ([TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType]) {
        if (self.isSearching) {
            cell.textView.attributedText = cell.textView.text ? [[NSAttributedString alloc] initWithAttributedString:[self getSearchKeywordColored:cell.textView.text isCurrentPath:[self.searchingIndexPath isEqual:indexPath] chatFont:chatFont]] : nil;
        } else {
            cell.textView.attributedText = cell.textView.text ? [[NSAttributedString alloc] initWithString:cell.textView.text attributes:@{NSBackgroundColorAttributeName : [UIColor clearColor], NSFontAttributeName:chatFont}] : nil;
        }
        cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName : cell.textView.textColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)};
        
        if ([self hasImageThumbUrlForSystemNotificationMessage:message]) {
            NSArray *messageComponents = [message.message componentsSeparatedByString:@"|"];
            NSString *imageThumbUrlComponent = messageComponents[INDEX_OF_MESSAGE_SYSTEM_NOTIFICATION_SERVER_THUMB_URL];
            [cell.systemNotificationImageView setLocalImageWithURL:[NSURL URLWithString:imageThumbUrlComponent] placeholderImage:[UIImage imageNamed:IMAGE_NAME_PLACEHOLDER_CHAT_PHOTO]];
        }
    }
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([TYPE_MESSAGE_INVITE isEqualToString:message.messageType] || [TYPE_MESSAGE_LEAVE isEqualToString:message.messageType] || [TYPE_MESSAGE_SHARE_SETTING isEqualToString:message.messageType] || [TYPE_MESSAGE_UPDATE_CHATNO isEqualToString:message.messageType]) {
        return NO;
    }
    if (action == @selector(deleteChatMessage:) || action == @selector(resendChatMessage:) || action == @selector(forwardChatMessage:)) {
        return YES;
    } else if (action == @selector(copy:)) {
        if ([TYPE_MESSAGE_FILE isEqualToString:message.messageType] || [TYPE_MESSAGE_STICKER isEqualToString:message.messageType] || [TYPE_MESSAGE_IMAGE isEqualToString:message.messageType]) {
            return NO;
        }
        if ([TYPE_MESSAGE_TEXT isEqualToString:message.messageType] && [USE_CHATROOM_TEXT_LIMIT isEqualToString:@"YES"]) {
            if (self.useTextCopy) {
                return YES;
            } else {
                return NO;
            }
        }
    } else if (action == @selector(reuseChatMessage:)) {
        if ([TYPE_MESSAGE_TEXT isEqualToString:message.messageType] || [TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType]) {
            return YES;
        }
    } else if (action == @selector(postNoticeWithChatMessage:)) {
        if ([TYPE_MESSAGE_TEXT isEqualToString:message.messageType] || [TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType]) {
            return YES;
        }
    } else if (action == @selector(autoTextChatMessage:)) {
        if ([TYPE_MESSAGE_TEXT isEqualToString:message.messageType] || [TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType]) {
            return YES;
        }
    } else if (action == @selector(getUnreadUserCountWithChatMessage:)) {
        if ([self isTypeChatroomLiteWithChatNo:self.currentChat.chatNo]) {
            return YES;
        }
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(deleteChatMessage:)) {
        [self deleteChatMessage:sender];
        return;
    }
    if (action == @selector(resendChatMessage:)) {
        [self resendChatMessage:sender];
        return;
    }
    if (action == @selector(forwardChatMessage:)) {
        [self forwardChatMessage:sender];
        return;
    }
    if (action == @selector(reuseChatMessage:)) {
        [self reuseChatMessage:sender];
        return;
    }
    if (action == @selector(postNoticeWithChatMessage:)) {
        [self postNoticeWithChatMessage:sender];
        return;
    }
    if (action == @selector(autoTextChatMessage:)) {
        [self autoTextChatMessage:sender];
        return;
    }
    if (action == @selector(getUnreadUserCountWithChatMessage:)) {
        [self getUnreadUserCountWithChatMessage:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if ([USE_CHATROOM_TOBOTTOM_BUTTON isEqualToString:@"YES"] && self.showLastReadCellTopBelowLabelText && indexPath.item > 0) {
        Message *previousChatMessage = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section]];
        NSInteger previousChatMessageSeq = previousChatMessage.messageSeq ? [previousChatMessage.messageSeq integerValue] : -1;
        if (self.lastReadMessageSeq > 0 && self.lastReadMessageSeq == previousChatMessageSeq) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopBelowLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if (message.messageDate) {
        if (indexPath.item == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        } else {
            Message *previousMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section]];
            if ([CommonUtils daysFromDate:previousMessage.messageDate toDate:message.messageDate] > 0) {
                return kJSQMessagesCollectionViewCellLabelHeightDefault;
            }
        }
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return 0.0f;
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 10.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomCountLabelAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if (![self needShowMessageFailButtonForMessage:message] && ([self.currentChat.groupYN boolValue] || [self.senderId isEqualToString:message.senderId])) {
        if ([self isTypeChatroomLiteWithChatNo:self.currentChat.chatNo]) {
            return 0.0f;
        } else {
            NSInteger unreadUserCount = [message.unreadUserCount integerValue];
            if (unreadUserCount > 0) {
                return 12.0f;
            }
        }
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomFailButtonAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([self needShowMessageFailButtonForMessage:message] && [self.senderId isEqualToString:message.senderId]) {
        return 20.0f;
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleSize:(CGSize)messageBubbleSize heightForSystemNotificationMessageImageViewAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    if ([TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType] && [self hasImageThumbUrlForSystemNotificationMessage:message]) {
        return messageBubbleSize.width * 3 / 4;
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForGotoSystemNotificationButtonsContainerViewAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self messageAtIndexPath:indexPath];
    
    if ([TYPE_MESSAGE_SYSTEM_NOTIFICATION isEqualToString:message.messageType] && [self hasLinkUrlAndSystemIdForSystemNotificationMessage:message]) {
        return 46.0f;
    }
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods


- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.demoData.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

@end
