//
//  ImageViewController.m
//  Imaginarium
//
//  Created by Ginny Fahs on 1/23/19.
//  Copyright © 2019 Ginny's Games. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end

// don't need @synthesize for image bc we never use the instance variable

@implementation ImageViewController
-(void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;

    _scrollView.minimumZoomScale = 0.2;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

-(void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    // this call has potential to block the main queue
//    self.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
    [self startDownloadingImage];
}

-(void)startDownloadingImage
{
    self.image = nil;
    if (self.imageURL) {
        [self.spinner startAnimating];
        NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        // callback will be on a different queue, not the main queue
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                          // the file only lives as long as it takes the block to execute code
                                          // if you want to keep the file longer, you need to copy
                                                        completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                                                            // when this is done, we want self.image to be set on the main queue
                                                            // the new queue is getting created here
                                                            if (!error) {
                                                                // checking to confirm that user didn't select a different image URL while waiting
                                                                if ([request.URL isEqual:self.imageURL]) {
                                                                    // cannot block bc local file
                                                                    // we ARE allowed to manipulate UIImage off of the queue (one of the few times) bc we're not actually doing anyhting on screen, just creating a local variable
                                                                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localFile]];
                                                                    // setting the image DOES need to happen on the main thread
                                                                    dispatch_async(dispatch_get_main_queue(), ^{ self.image = image; });
                                                                    // synonymous with above:
//                                                                    [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
                                                                }
                                                            }
                                                        }];
        // need to say this so that block does not wait suspended
        [task resume];
        
    }
}

-(UIImageView *)imageView
{
    if (!_imageView) _imageView = [[UIImageView alloc] init];
    return _imageView;
}

-(UIImage *)image
{
    return self.imageView.image;
}

-(void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    [self.imageView sizeToFit];
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    [self.spinner stopAnimating];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
}


@end
