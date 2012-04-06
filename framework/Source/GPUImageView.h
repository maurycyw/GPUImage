#import <UIKit/UIKit.h>
#import "GPUImageOpenGLESContext.h"

@interface GPUImageView : UIView <GPUImageInput>
{
}

@property(readonly, nonatomic) CGSize sizeInPixels;

/**
 * returns the instantaneous render frames per second.
 */
@property(readonly, nonatomic) float framesPerSecond;

@end
