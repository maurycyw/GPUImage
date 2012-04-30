#import "GPUImageOutput.h"

void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
	if ([NSThread isMainThread])
	{
		block();
	}
	else
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
}

@implementation GPUImageOutput

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;
@synthesize shouldIgnoreUpdatesToThisTarget = _shouldIgnoreUpdatesToThisTarget;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init; 
{
	if (!(self = [super init]))
    {
		return nil;
    }

    targets = [[NSMutableArray alloc] init];
    targetTextureIndices = [[NSMutableArray alloc] init];
    
    [self initializeOutputTexture];

    return self;
}

- (void)dealloc 
{
    [self removeAllTargets];
    [self deleteOutputTexture];
}

#pragma mark -
#pragma mark Managing targets

- (void)setInputTextureForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputTexture:outputTexture atIndex:inputTextureIndex];
}

- (void)addTarget:(id<GPUImageInput>)newTarget;
{
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
    if ([newTarget shouldIgnoreUpdatesToThisTarget])
    {
        targetToIgnoreForUpdates = newTarget;
    }
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    [self setInputTextureForTarget:newTarget atIndex:textureLocation];
    [targets addObject:newTarget];
    [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    if (targetToIgnoreForUpdates == targetToRemove)
    {
        targetToIgnoreForUpdates = nil;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    [targetToRemove setInputSize:CGSizeZero];
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    [targetToRemove setInputTexture:0 atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
    [targetTextureIndices removeObjectAtIndex:indexOfObject];
    [targets removeObject:targetToRemove];
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    for (id<GPUImageInput> targetToRemove in targets)
    {
        [targetToRemove setInputSize:CGSizeZero];

        NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
        [targetToRemove setInputTexture:0 atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
    }
    [targets removeAllObjects];
    [targetTextureIndices removeAllObjects];
}

#pragma mark -
#pragma mark Manage the output texture

- (void)initializeOutputTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &outputTexture);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // notify targets
    for (id<GPUImageInput> target in targets) {
        [target setInputTexture:outputTexture atIndex:0];
    }
}

- (void)deleteOutputTexture;
{
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
        // notify targets
        for (id<GPUImageInput> target in targets) {
            [target setInputTexture:outputTexture atIndex:0];
        }
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    
}

#pragma mark -
#pragma mark Still image processing

- (UIImage *)imageFromCurrentlyProcessedOutput;
{
    return nil;
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    return nil;
}

#pragma mark -
#pragma mark Accessors


@end
