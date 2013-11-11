//
//  ImageController.m
//  ImageTargets
//
//  Created by libor on 31/10/13.
//
//

#import "ImageController.h"
#import <Social/Social.h>
#import "ActivityInstagram.h"

@implementation ImageController

bool shareViewShowed;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSString *nib;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
        nib = @"ImageController";
    } else {
        nib = @"ImageController";
    }
    
    self = [super initWithNibName:nib bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.imageView.contentMode = UIViewContentModeScaleToFill;
//    _savedImage = [UIImage imageWithCGImage:[_savedImage CGImage] scale: 5.5f orientation:UIImageOrientationLeftMirrored];
    [self.imageView setImage: _savedImage];
    
    NSLog(@"%f, %f", self.imageView.frame.size.width, self.imageView.frame.size.height);
    NSLog(@"%f, %f", self.savedImage.size.width, self.savedImage.size.height);


//    NSLog(@"UIView: %f %f", self.view.frame.size.width, self.view.frame.size.height);
//    NSLog(@"UIImageView: %f %f", self.imageView.frame.size.width, self.imageView.frame.size.height);
    shareViewShowed = NO;
    
    [[self shareView] setFrame: CGRectMake([self view].frame.size.width - _shareView.frame.size.width,
                                           _imageView.frame.origin.y,
                                           _shareView.frame.size.width,
                                           _shareView.frame.size.height)];
    
    // Do any additional setup after loading the view from its nib.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)discardImage:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//- (IBAction)shareFacebook:(id)sender {
//    [_shareView removeFromSuperview];
//    
//    if ([SLComposeViewController isAvailableForServiceType: SLServiceTypeFacebook]) {
//        SLComposeViewController *controller =
//            [SLComposeViewController composeViewControllerForServiceType: SLServiceTypeFacebook];
//        [controller setInitialText: @"Insania app"];
//        [controller addImage: _savedImage];
//        [self presentViewController: controller animated:YES completion:nil];
//    }
//}
//
//- (IBAction)shareTwitter:(id)sender {
//    [_shareView removeFromSuperview];
//    
//    if ([SLComposeViewController isAvailableForServiceType: SLServiceTypeTwitter]) {
//        SLComposeViewController *controller =
//            [SLComposeViewController composeViewControllerForServiceType: SLServiceTypeTwitter];
//        [controller setInitialText: @"Insania app"];
//        [controller addImage: _savedImage];
//        [self presentViewController: controller animated:YES completion:nil];
//    }
//    
//}
//
//- (IBAction)shareInstagram:(id)sender {
//    [_shareView removeFromSuperview];
//    
//    DMActivityInstagram *instagramActivity = [[DMActivityInstagram alloc] init];
//    
//    NSString *shareText = @"Insania iOS App";
//    NSURL *shareURL = [NSURL URLWithString:@"http://insania.app"];
//    
//    NSArray *activityItems = @[self.imageView.image, shareText, shareURL];
//    
//    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[instagramActivity]];
//    [self presentViewController:activityController animated:YES completion:nil];
//}

- (IBAction)shareButtonPushed:(id)sender {
    [self.view addSubview: _shareView];
    shareViewShowed = YES;
}

- (IBAction)sharePushed:(id)sender {
    [_shareView removeFromSuperview];
    
    DMActivityInstagram *instagramActivity = [[DMActivityInstagram alloc] init];

    NSString *shareText = @"Taken with InsaniaApp";
    NSURL *shareURL = [NSURL URLWithString:@"insania.cz"];

    NSArray *activityItems = @[self.imageView.image, shareText, shareURL];

    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[instagramActivity]];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)openInPushed:(id)sender {
    [_shareView removeFromSuperview];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]])
    {
        NSData *imageData = UIImagePNGRepresentation(_savedImage);
        NSString *writePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"instagram.ig"];
        if (![imageData writeToFile:writePath atomically:YES]) {
            // failure
            NSLog(@"image save failed to path %@", writePath);
            return;
        } else {
            NSURL *fileURL = [NSURL fileURLWithPath:writePath];
            interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
            interactionController.delegate = self;
            [interactionController setUTI:@"com.instagram.photo"];
            interactionController.annotation = @{@"InstagramCaption" : NSLocalizedString(@"Insania App", nil)};
            
            CGRect appRect = [[UIScreen mainScreen] bounds];
            CGSize rectSize = CGSizeMake(appRect.size.width, 300);
            CGRect shareRect = CGRectMake(0, appRect.origin.y - rectSize.height, rectSize.width, rectSize.height);
            if (![interactionController presentOpenInMenuFromRect:shareRect inView:self.view animated:YES]) NSLog(@"couldn't present document interaction controller");
        }
    }
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
        [_shareView removeFromSuperview];
        shareViewShowed = NO;
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // iOS requires all events handled if touchesBegan is handled and not forwarded
}



- (void)dealloc {
    [_imageView release];
    [_shareView release];
    [_customNavigationBar release];
    [super dealloc];
}
@end
