#import <substrate.h>
#import "InstagramHeaders.h"
#import "Tweak.h"
#import "Utils.h"

///////////////////////////////////////////////////////////

// Screenshot handlers

#define VOID_HANDLESCREENSHOT(orig) [SCIUtils getBoolPref:@"remove_screenshot_alert"] ? nil : orig;
#define NONVOID_HANDLESCREENSHOT(orig) return VOID_HANDLESCREENSHOT(orig)

///////////////////////////////////////////////////////////

// * Tweak version *
NSString *SCIVersionString = @"v1.1.1";

// Păstrăm variabila ca să nu dea eroare de compilare în Settings, dar rămâne dezactivată
BOOL dmVisualMsgsViewedButtonEnabled = false;

// Tweak first-time setup
%hook IGInstagramAppDelegate
- (_Bool)application:(UIApplication *)application willFinishLaunchingWithOptions:(id)arg2 {

    // Default SCInsta config (Optimizat pentru curățenie din fabrică)
    NSDictionary *sciDefaults = @{
        @"hide_ads": @(YES),
        @"hide_meta_ai": @(YES),
        @"no_suggested_users": @(YES),
        @"no_suggested_chats": @(YES),
        @"hide_notes_tray": @(NO),
        @"copy_description": @(YES),
        @"detailed_color_picker": @(YES),
        @"remove_screenshot_alert": @(YES),
        @"call_confirm": @(YES),
        @"keep_deleted_message": @(YES),
        @"dw_feed_posts": @(YES),
        @"dw_reels": @(YES),
        @"dw_story": @(YES),
        @"save_profile": @(YES),
        @"dw_finger_count": @(3),
        @"dw_finger_duration": @(0.5),
        @"reels_tap_control": @"default",
        @"nav_icon_ordering": @"default",
        @"swipe_nav_tabs": @"default",
        @"enable_notes_customization": @(YES),
        @"custom_note_themes": @(YES),
        @"disable_auto_unmuting_reels": @(YES),
        @"doom_scrolling_reel_count": @(1)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:sciDefaults];
    
    // Override instagram defaults
    if ([SCIUtils getBoolPref:@"liquid_glass_buttons"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"instagram.override.project.lucent.navigation"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"instagram.override.project.lucent.navigation"];
    }

    return %orig;
}
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {

    %orig;

    // Open settings for first-time users
    double openDelay = [SCIUtils getBoolPref:@"tweak_settings_app_launch"] ? 0.0 : 5.0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(openDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (
            ![[[NSUserDefaults standardUserDefaults] objectForKey:@"SCInstaFirstRun"] isEqualToString:SCIVersionString]
            || [SCIUtils getBoolPref:@"tweak_settings_app_launch"]
        ) {
            NSLog(@"[SCInsta] First run, initializing");

            // Display settings modal on screen
            NSLog(@"[SCInsta] Displaying SCInsta first-time settings modal");
            [SCIUtils showSettingsVC:[self window]];
        }
    });

    NSLog(@"[SCInsta] Cleaning cache...");
    [SCIUtils cleanCache];

    if ([SCIUtils getBoolPref:@"flex_app_launch"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }

    return true;
}

- (void)applicationDidBecomeActive:(id)arg1 {

    %orig;
    
    if ([SCIUtils getBoolPref:@"flex_app_start"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

%hook IGDSLauncherConfig
- (_Bool)isLiquidGlassInAppNotificationEnabled {
    return [SCIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassContextMenuEnabled{
    return [SCIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassToastEnabled {
    return [SCIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassToastPeekEnabled {
    return [SCIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassAlertDialogEnabled {
    return [SCIUtils liquidGlassEnabledBool:%orig];
}
%end

// Disable sending modded insta bug reports
%hook IGWindow
- (void)showDebugMenu {
    return;
}
%end

%hook IGBugReportUploader
- (id)initWithNetworker:(id)arg1
       pandoGraphQLService:(id)arg2
           analyticsLogger:(id)arg3
              userDefaults:(id)arg4
       launcherSetProvider:(id)arg5
shouldPersistLastBugReportId:(id)arg6
{
    return nil;
}
%end

// Disable anti-screenshot feature on visual messages
%hook IGStoryViewerContainerView
- (void)setShouldBlockScreenshot:(BOOL)arg1 viewModel:(id)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

// Disable screenshot logging/detection
%hook IGDirectVisualMessageViewerSession
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReplayService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReportService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageScreenshotSafetyLogger
- (id)initWithUserSession:(id)arg1 entryPoint:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) {
        NSLog(@"[SCInsta] Disable visual message screenshot safety logger");
        return nil;
    }
    return %orig;
}
%end

%hook IGScreenshotObserver
- (id)initForController:(id)arg1 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGScreenshotObserverDelegate
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectMediaViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGStoryViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGSundialFeedViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageViewerController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

/////////////////////////////////////////////////////////////////////////////

// Hide items

// Direct suggested chats (in search bar)
%hook IGDirectInboxSearchListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {

    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Section header 
        if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

            // Broadcast channels
            if ([[obj valueForKey:@"uniqueIdentifier"] isEqualToString:@"channels"]) {
                if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
                    shouldHide = YES;
                }
            }

            // Ask Meta AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    shouldHide = YES;
                }
            }

            // AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    shouldHide = YES;
                }
            }
            
        }

        // AI agents section
        else if (
            [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsPillsSectionViewModel)]
           || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptViewModel)]
           || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptLoggingViewModel)]
        ) {
            if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                shouldHide = YES;
            }
        }

        // Recipients list
        else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

            // Broadcast channels
            if ([[obj recipient] isBroadcastChannel]) {
                if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
                    shouldHide = YES;
                }
            }
            
            // Meta AI (special section types)
            else if (([obj sectionType] == 20) || [obj sectionType] == 18) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    shouldHide = YES;
                }
            }

            // Meta AI (catch-all)
            else if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    shouldHide = YES;
                }
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (thread creation view)
%hook IGDirectThreadCreationViewController
- (id)objectsForListAdapter:(id)arg1 {

    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
            if ([obj isKindOfClass:%c(IGDirectCreateChatCellViewModel)]) {
                if ([[obj valueForKey:@"title"] isEqualToString:@"AI chats"]) {
                    shouldHide = YES;
                }
            }
            else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {
                if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                    shouldHide = YES;
                }
            }
        }

        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGContactInvitesSearchUpsellViewModel)]) {
                shouldHide = YES;
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (inbox view)
%hook IGDirectInboxListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {

    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([obj isKindOfClass:%c(IGDirectInboxHeaderCellViewModel)]) {
            if ([[obj title] isEqualToString:@"Suggestions"] || [[obj title] hasPrefix:@"Accounts to"]) {
                if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                    shouldHide = YES;
                }
            }
        }
        else if ([obj isKindOfClass:%c(IGDirectInboxSuggestedThreadCellViewModel)]) {
            if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                shouldHide = YES;
            }
        }
        else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)] || [obj isKindOfClass:%c(IGDiscoverPeopleConnectionItemConfiguration)]) {
            if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                shouldHide = YES;
            }
        }
        else if ([obj isKindOfClass:%c(IGDirectNotesTrayRowViewModel)]) {
            if ([SCIUtils getBoolPref:@"hide_notes_tray"]) {
                shouldHide = YES;
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Explore page results
%hook IGSearchListKitDataSource
- (id)objectsForListAdapter:(id)arg1 {

    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                    shouldHide = YES;
                }
            }
            else if ([obj isKindOfClass:%c(IGSearchNullStateUpsellViewModel)] || [obj isKindOfClass:%c(IGSearchResultNestedGroupViewModel)]) {
                shouldHide = YES;
            }
            else if ([obj isKindOfClass:%c(IGSearchResultViewModel)]) {
                if ([obj itemType] == 6 || [[[obj title] string] isEqualToString:@"meta.ai"]) {
                    shouldHide = YES;
                }
            }
        }

        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Suggested for you"]) {
                    shouldHide = YES;
                }
            }
            else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)]) {
                shouldHide = YES;
            }
            else if ([obj isKindOfClass:%c(IGSeeAllItemConfiguration)] && ((IGSeeAllItemConfiguration *)obj).destination == 4) {
                shouldHide = YES;
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Story tray
%hook IGMainStoryTrayDataSource
- (id)allItemsForTrayUsingCachedValue:(BOOL)cached {

    NSArray *originalObjs = %orig(cached);
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (IGStoryTrayViewModel *obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)]) {
                NSNumber *type = [((IGStoryTrayViewModel *)obj) valueForKey:@"type"];
                if ([type isEqual:@(8)] || [type isEqual:@(9)]) {
                    shouldHide = YES;
                }
            }
        }

        if ([SCIUtils getBoolPref:@"hide_ads"]) {
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)] && (obj.isUnseenNux == YES || [obj.pk isEqualToString:@"3538572169"])) {
                shouldHide = YES;
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

%hook IGStoryTraySectionController
- (void)storyTrayControllerShowSUPOGEducationBump {
    if ([SCIUtils getBoolPref:@"no_suggested_users"]) return;
    return %orig();
}
%end

%hook IGDSMenu
- (id)initWithMenuItems:(NSArray<IGDSMenuItem *> *)originalObjs edr:(BOOL)edr headerLabelText:(id)headerLabelText {

    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([[obj valueForKey:@"title"] isEqualToString:@"AI images"] || [[obj valueForKey:@"title"] isEqualToString:@"Meta AI"]) {
            if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                shouldHide = YES;
            }
        }

        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return %orig([filteredObjs copy], edr, headerLabelText);
}
%end

/////////////////////////////////////////////////////////////////////////////

// Confirm buttons

%hook IGFeedItemUFICell
- (void)UFIButtonBarDidTapOnLike:(id)arg1 {
    if ([SCIUtils getBoolPref:@"like_confirm"]) {
        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }  
}
- (void)UFIButtonBarDidTapOnRepost:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 {
    if (![SCIUtils getBoolPref:@"repost_confirm"]) return %orig;
}
- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 withGestureRecognizer:(id)arg2 {
    if (![SCIUtils getBoolPref:@"repost_confirm"]) return %orig;
}
%end

%hook IGSundialViewerVerticalUFI
- (void)_didTapLikeButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"like_confirm_reels"]) {
        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
- (void)_didLongPressLikeButton:(id)arg1 {
    if (![SCIUtils getBoolPref:@"like_confirm_reels"]) return %orig;
}
- (void)_didTapRepostButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
- (void)_didLongPressRepostButton:(id)arg1 {
    if (![SCIUtils getBoolPref:@"repost_confirm"]) return %orig;
}
%end

/////////////////////////////////////////////////////////////////////////////

// FLEX explorer gesture handler
%hook IGRootViewController
- (void)viewDidLoad {
    %orig;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1;
    longPress.numberOfTouchesRequired = 5;
    [self.view addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    if ([SCIUtils getBoolPref:@"flex_instagram"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

// Disable safe mode
%hook IGSafeModeChecker
- (id)initWithInstacrashCounterProvider:(void *)provider crashThreshold:(unsigned long long)threshold {
    if ([SCIUtils getBoolPref:@"disable_safe_mode"]) return nil;
    return %orig(provider, threshold);
}
- (unsigned long long)crashCount {
    if ([SCIUtils getBoolPref:@"disable_safe_mode"]) return 0;
    return %orig;
}
%end

/////////////////////////////////////////////////////////////////////////////
// --- SUPERINSTA CUSTOM AESTHETIC (Slate-Grey, Fără Buline, Fără Reels) ---
/////////////////////////////////////////////////////////////////////////////

// 1. Elimină toate bulinele roșii și notificările de tip punct
%hook UIView
- (void)layoutSubviews {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Badge"] || [cls containsString:@"UnreadBubble"] || [cls containsString:@"DotView"]) {
        self.hidden = YES;
        self.alpha = 0.0;
    }
}
%end

%hook IGBadgeView
- (void)layoutSubviews { %orig; self.hidden = YES; self.alpha = 0.0; }
%end

%hook _UIBadgeView
- (void)layoutSubviews { %orig; self.hidden = YES; self.alpha = 0.0; }
%end

// 2. Transformă cercurile de Story din roz/portocaliu în Slate-Grey
%hook CAGradientLayer
- (void)setColors:(NSArray *)colors {
    if (colors && [colors count] > 1) {
        id slateTop = (id)[UIColor colorWithRed:0.42 green:0.45 blue:0.48 alpha:1.0].CGColor;
        id slateBot = (id)[UIColor colorWithRed:0.22 green:0.24 blue:0.27 alpha:1.0].CGColor;
        colors = @[slateTop, slateBot];
    }
    %orig(colors);
}
%end

// 3. Ascunde butonul de Reels din bara de jos
%hook IGTabBarButton
- (void)layoutSubviews {
    %orig;
    NSString *label = [self.accessibilityLabel lowercaseString];
    if (label && ([label containsString:@"reels"] || [label containsString:@"clips"])) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        self.frame = CGRectZero;
    }
}
%end
