/*==============================================================================
 Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/

#import "AboutViewController.h"
#import "ImageTargetsQCARutils.h"

@implementation AboutViewController

#pragma mark - Private
- (id)init
{
    NSString *nib;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
        
        nib = @"AboutViewController";
    } else {
        nib = @"AboutViewController";
    }
    
    self = [super initWithNibName:nib bundle: nil];
    self.view.frame = [[UIScreen mainScreen] applicationFrame];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadWebView
{
    //  Load html from a local file for the about screen
    NSString *aboutFilePath = [[NSBundle mainBundle] pathForResource:@"about"
                                                              ofType:@"html"];
    
    NSString* htmlString = [NSString stringWithContentsOfFile:aboutFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSString *aPath = [[NSBundle mainBundle] bundlePath];
    NSURL *anURL = [NSURL fileURLWithPath:aPath];
    [webView loadHTMLString:htmlString baseURL:anURL];
    
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
            _aboutImage.image = [UIImage imageNamed:@"01_about_640x1136.png"];
    } else {
        if(IS_IPHONE_5)
        {
            _aboutImage.image = [UIImage imageNamed:@"01_about_640x1136.png"];
        }
        else
        {
            _aboutImage.image = [UIImage imageNamed:@"01_about_640x960.png"];
        }
    }
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// touch handlers
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    // iOS requires all events handled if touchesBegan is handled and not forwarded
    UITouch* touch = [touches anyObject];
    
    int tc = [touch tapCount];
    if (tc) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // iOS requires all events handled if touchesBegan is handled and not forwarded
}

#pragma mark - Public

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadWebView];
}

- (void)viewDidUnload
{
    [webView release];
    webView = nil;
    [super viewDidUnload];
}

//  Deprecated on iOS 6. Use the two methods below to control autorotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    ImageTargetsQCARutils *utils = [ImageTargetsQCARutils getInstance];
    BOOL retVal = [utils shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    
    return retVal;
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger retVal = [[ImageTargetsQCARutils getInstance] supportedInterfaceOrientations];
    return retVal;
}

- (BOOL)shouldAutorotate
{
    BOOL retVal = [[ImageTargetsQCARutils getInstance] shouldAutorotate];
    return retVal;
}

- (void)dealloc
{
    [webView release];
    [_aboutImage release];
    [super dealloc];
}

#pragma mark - UIWebViewDelegate

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    //  Opens the links within this UIWebView on a safari web browser
    
    BOOL retVal = NO;
    
    if ( inType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
    }
    else
    {
        retVal = YES;
    }
    
    return retVal;
}
@end
