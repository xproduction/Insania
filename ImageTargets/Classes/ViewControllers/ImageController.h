//
//  ImageController.h
//  ImageTargets
//
//  Created by libor on 31/10/13.
//
//

#import <UIKit/UIKit.h>

@interface ImageController : UIViewController <UIDocumentInteractionControllerDelegate> {
    UIDocumentInteractionController *interactionController;
}

@property (nonatomic, strong) UIImage *savedImage;

@property (retain, nonatomic) IBOutlet UIImageView *imageView;

@property (retain, nonatomic) IBOutlet UIView *shareView;

@property (retain, nonatomic) IBOutlet UINavigationBar *customNavigationBar;

- (IBAction)discardImage:(id)sender;

- (BOOL)prefersStatusBarHidden;

- (IBAction)shareButtonPushed:(id)sender;

- (IBAction)openInPushed:(id)sender;

- (IBAction)sharePushed:(id)sender;

@end
