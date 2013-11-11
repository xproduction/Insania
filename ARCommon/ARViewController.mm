/*==============================================================================
 Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/

#import <QuartzCore/QuartzCore.h>

#import "ARViewController.h"
#import "QCARutils.h"
#import "EAGLView.h"
#import "Texture.h"
#import "ImageController.h"

@interface ARViewController ()
- (void) unloadViewData;
- (void) handleARViewRotation:(UIInterfaceOrientation)interfaceOrientation;
@end

@implementation ARViewController

int iconWidth;
int iconHeight;

@synthesize arView;
@synthesize arViewSize;

- (id)init
{
    self = [super init];
    if (self) {
        qUtils = [QCARutils getInstance];
    }
    return self;
}

- (void)dealloc
{
    [self unloadViewData];
    [super dealloc];
}


- (void) unloadViewData
{
    // undo everything created in loadView and viewDidLoad
    // called from dealloc and viewDidUnload so has to be defensive
    
    // Release the textures array
    if (textures != nil)
    {
        [textures release];
        textures = nil;
    }
    
    [qUtils destroyAR];
    
    if (arView != nil)
    {
        [arView release];
        arView = nil;
    }
    
    if (parentView != nil)
    {
        [parentView release];
        parentView = nil;
    }
}

#pragma mark --- View lifecycle ---
// Implement loadView to create a view hierarchy programmatically, without using a nib.
// Invoked when UIViewController.view is accessed for the first time.
- (void)loadView
{
    NSLog(@"ARVC: loadView");
    
    // We are going to rotate our EAGLView by 90/270 degrees as the camera's idea of orientation is different to the screen,
    // so its width must be equal to the screen's height, and height to width
    CGRect viewBounds;
    viewBounds.origin.x = 0;
    viewBounds.origin.y = 0;
    viewBounds.size.width = arViewSize.height;
    viewBounds.size.height = arViewSize.width;
    arView = [[EAGLView alloc] initWithFrame: viewBounds];
    
    // we add a parent view as EAGLView doesn't like being the immediate child of a VC
    parentView = [[UIView alloc] initWithFrame: viewBounds];
    [parentView addSubview:arView];
    self.view = parentView;
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    
//    _cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    appFrame = [[UIScreen mainScreen] bounds];
    
    UIImage *cameraIcon = [UIImage imageNamed:@"02_cameraButton_1.png"];
    
    _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_cameraButton setImage: cameraIcon forState:UIControlStateNormal];
    
    
    iconWidth = 320;
    iconHeight = 70;
    
    _cameraButton.frame = CGRectMake( 0,
                                  appFrame.size.height - iconHeight ,
                                  iconWidth,
                                  iconHeight
                                  );
    [_cameraButton addTarget: self action: @selector(saveImage:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview: _cameraButton];
    [self.view setFrame: appFrame];
}


- (void)viewDidLoad
{
    NSLog(@"ARVC: viewDidLoad");
    
    // load the list of textures requested by the view, and tell it about them
    if (textures == nil)
        textures=[qUtils loadTextures:arView.textureList];
    [arView useTextures:textures];
   
    // set the view size for initialisation, and go do it...
    [qUtils createARofSize:arViewSize forDelegate:arView];
    arVisible = YES;

}


- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"ARVC: viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated
{
    // resume here as in viewWillAppear the view hasn't always been stitched into the hierarchy
    // which means QCAR won't find our EAGLView
    NSLog(@"ARVC: viewDidAppear");
    if (arVisible == NO)
        [qUtils resumeAR];
    
    arVisible = YES;    
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"ARVC: viewDidDisappear");
    if (arVisible == YES)
        [qUtils pauseAR];
    
    // Be a good OpenGL ES citizen: ensure all commands have finished executing
    [arView finishOpenGLESCommands];
    
    arVisible = NO;
}


- (void)viewDidUnload
{
    NSLog(@"ARVC: viewDidUnload");
    
    [super viewDidUnload];
    
    [self unloadViewData];
}


- (void) handleARViewRotation:(UIInterfaceOrientation)interfaceOrientation
{
    CGPoint centre, pos;
    NSInteger rot;

    // Set the EAGLView's position (its centre) to be the centre of the window, based on orientation
    centre.x = arViewSize.width / 2;
    centre.y = arViewSize.height / 2;
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        NSLog(@"ARVC: Rotating to Portrait");
        pos = centre;
        rot = 90;
    }
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        NSLog(@"ARVC: Rotating to Upside Down");        
        pos = centre;
        rot = 270;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        NSLog(@"ARVC: Rotating to Landscape Left");        
        pos.x = centre.y;
        pos.y = centre.x;
        rot = 180;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        NSLog(@"ARParent: Rotating to Landscape Right");
        pos.x = centre.y;
        pos.y = centre.x;
        rot = 0;
    }

    arView.layer.position = pos;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(rot * M_PI  / 180);
    arView.transform = rotate;
}


// Free any OpenGL ES resources that are easily recreated when the app resumes
- (void)freeOpenGLESResources
{
    [arView freeOpenGLESResources];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


-(UIImage*) glToUIImage {
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect s;
    if ([[[UIDevice currentDevice] model] isEqualToString:@"iPad"])
        s = CGRectMake(0, 0, (1024.0f) * scale, 768.0f * scale);
    else
        s = CGRectMake(0, 0, (480.0f) * scale, 320.0f * scale);
    
    uint8_t *buffer = (uint8_t *) malloc(s.size.width * s.size.height * 4);
    glReadPixels(0, 0, s.size.width, s.size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, buffer, s.size.width * s.size.height * 4, NULL);
    CGImageRef iref = CGImageCreate(s.size.width, s.size.height, 8, 32, s.size.width * 4, CGColorSpaceCreateDeviceRGB(),
                                    kCGBitmapByteOrderDefault, ref, NULL, true, kCGRenderingIntentDefault);
    
    size_t width = CGImageGetWidth(iref);
    size_t height = CGImageGetHeight(iref);
    size_t length = width * height * 4;
    
    uint32_t *pixels = (uint32_t *)malloc(length);
    CGContextRef loContext = CGBitmapContextCreate(pixels, width, height, 8, width * 4,
                                                   CGImageGetColorSpace(iref), kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
    CGContextDrawImage(loContext, CGRectMake(0.0f, 0.0f, width, height), iref);
    CGImageRef outputRef = CGBitmapContextCreateImage(loContext);
    UIImage * outputImage;
    outputImage = [[UIImage alloc] initWithCGImage:outputRef scale:(CGFloat)1.0 orientation:UIImageOrientationLeftMirrored];
    
    CGDataProviderRelease(ref);
    CGImageRelease(iref);
    CGContextRelease(loContext);
    CGImageRelease(outputRef);
    free(pixels);
    free(buffer);
    
    NSLog(@"Screenshot size: %d, %d", (int)[outputImage size].width, (int)[outputImage size].height);
    
    return outputImage;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        _cameraButton.frame = CGRectMake( 0,
                                         appFrame.size.height - iconHeight ,
                                         iconWidth,
                                         iconHeight
                                         );
    } else {
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        
        [_cameraButton setImage:[UIImage imageNamed:@"02_cameraButton_1.png"] forState:UIControlStateNormal];
        _cameraButton.frame = CGRectMake( 0,
                                         appFrame.size.height - iconHeight ,
                                         iconWidth,
                                         iconHeight
                                         );
    }
        
}

-(IBAction)saveImage:(UIButton *)sender {
    
    NSLog(@"pushed");
    
    while ([arView getRender]) {
    }
    
    [arView setScreenshot: YES];
    
    ImageController *ic = [[ImageController alloc] init];
    UIImage * image = [self glToUIImage];
    ic.savedImage = image;
    
    
    
    [arView setScreenshot: NO];
    [self presentViewController: ic animated:YES completion:nil];
}


@end
