// MobileTerminalAppDelegate.m
// MobileTerminal

#import "MobileTerminalAppDelegate.h"
#import "MobileTerminalViewController.h"

#import "Preferences/Settings.h"
#import "Preferences/MenuSettings.h"

// Automatically generated by build rules
#import "svnversion.h"


@implementation MobileTerminalAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize terminalViewController;
@synthesize preferencesViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
  Settings* settings = [Settings sharedInstance];
  settings.svnVersion = SVN_VERSION;
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  
  NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
  [viewControllers addObject:terminalViewController];  
  [navigationController setViewControllers:viewControllers animated:NO];
  [viewControllers release];
    
  [window addSubview:navigationController.view];
  [window makeKeyAndVisible];
}

static const NSTimeInterval kAnimationDuration = 1.00f;

- (void)preferencesButtonPressed
{
  [navigationController setNavigationBarHidden:NO];
  [navigationController pushViewController:preferencesViewController animated:YES];
}

- (void)preferencesDonePressed:(id)sender;
{
  [[Settings sharedInstance] persist];
  [navigationController popViewControllerAnimated:YES];
}

- (void)rootViewDidAppear
{
  // This must be invoked after the animation to show the root view completes
  [navigationController setNavigationBarHidden:YES];  
}

@end
