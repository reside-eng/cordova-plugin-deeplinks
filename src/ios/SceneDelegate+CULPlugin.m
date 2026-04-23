//
//  SceneDelegate+CULPlugin.m
//
//  Adds scene:continueUserActivity: to CDVSceneDelegate (new method — not
//  present on the base class) for the warm-resume path, and swizzles
//  scene:willConnectToSession:options: to also handle
//  connectionOptions.userActivities for the cold-start path.
//

#import "SceneDelegate+CULPlugin.h"
#import "CULPlugin.h"
#import <Cordova/CDVViewController.h>
#import <objc/runtime.h>

static NSString *const CUL_PLUGIN_NAME = @"UniversalLinks";

@implementation CDVSceneDelegate (CULPlugin)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [CDVSceneDelegate class];
        SEL originalSel = @selector(scene:willConnectToSession:options:);
        SEL swizzledSel = @selector(cul_scene:willConnectToSession:options:);

        Method originalMethod = class_getInstanceMethod(cls, originalSel);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSel);
        if (originalMethod == NULL || swizzledMethod == NULL) {
            return;
        }

        BOOL didAddMethod = class_addMethod(cls,
                                            originalSel,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(cls,
                                swizzledSel,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

// After swizzling, the `cul_scene:...` selector points at the original
// CDVSceneDelegate implementation, and `scene:...` points at this body.
// Call the original first, then inspect launch-time user activities.
- (void)cul_scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    [self cul_scene:scene willConnectToSession:session options:connectionOptions];

    for (NSUserActivity *activity in connectionOptions.userActivities) {
        [self scene:scene continueUserActivity:activity];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return;
    }
    if (userActivity.webpageURL == nil) {
        return;
    }

    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    UIViewController *root = windowScene.windows.firstObject.rootViewController;
    if (![root isKindOfClass:[CDVViewController class]]) {
        return;
    }
    CDVViewController *vc = (CDVViewController *)root;

    // On cold start, scene:willConnectTo fires before viewDidLoad, which is
    // where CDVViewController populates its _pluginsMap via loadSettings.
    // Touch .view to force loadView → viewDidLoad so getCommandInstance works.
    (void)vc.view;

    CULPlugin *plugin = (CULPlugin *)[vc getCommandInstance:CUL_PLUGIN_NAME];
    if (plugin == nil) {
        return;
    }

    [plugin handleUserActivity:userActivity];
}

@end
