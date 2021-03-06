#import "GPUImageStillCamera.h"
#import <CoreImage/CoreImage.h>

@interface GPUImageStillCamera ()
{
    AVCaptureStillImageOutput *photoOutput;
}

@end


@implementation GPUImageStillCamera

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack]))
    {
		return nil;
    }
    
    [self.captureSession beginConfiguration];
    
    photoOutput = [[AVCaptureStillImageOutput alloc] init];
    [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey]];
    
    [self.captureSession addOutput:photoOutput];
    
    [self.captureSession commitConfiguration];

    return self;
}

- (void)removeInputsAndOutputs;
{
    [self.captureSession removeOutput:photoOutput];
}

#pragma mark -
#pragma mark Photography controls

- (void)capturePhotoProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
{
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
        // Will need an alternate pathway for the iOS 4.0 support here

        UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentlyProcessedOutput];
        
        block(filteredPhoto, error);
        
    }];
    return;
}

- (void)capturePhotoRawWithCompletionHandler:(void (^)(UIImage *image, NSError *error))block;
{
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        if (nil != error || NULL == imageSampleBuffer || !CMSampleBufferIsValid(imageSampleBuffer)) {
            block(nil, error);
        }
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [UIImage imageWithData:jpegData];
        // we hard set the orientation to `up` because, honestly, let's not get all excited
        // about adding metadata to things before we've had a chance to process them, k?
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationUp];
        block(image, error);
    }];
    return;
}

@end
