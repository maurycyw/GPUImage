#import "GPUImageStillCamera.h"

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
    [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
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

- (void)capturePhotoRawWithCompletionHandler:(void (^)(CGImageRef rawImageRef, NSError *error))block;
{
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        // todo [scd] this is the starting point
        [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
        // Will need an alternate pathway for the iOS 4.0 support here
        // crop the image around the center 
        // new gpuimagefilter
        // pass in the texture
       
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(imageSampleBuffer); 
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0); 
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
        size_t width = CVPixelBufferGetWidth(imageBuffer); 
        size_t height = CVPixelBufferGetHeight(imageBuffer); 
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,  kCGImageAlphaPremultipliedLast); 
        CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
        
        /*We release some components*/
        CGContextRelease(newContext); 
        CGColorSpaceRelease(colorSpace);
        // 
        block(newImage, error);
        
    }];
    return;
}

@end
