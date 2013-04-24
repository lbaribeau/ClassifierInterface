/*
 * AppController.j
 * ClassifierInterface
 *
 * Created by You on April 9, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <Ratatosk/Ratatosk.j>
@import "Models/Classifier.j"
@import "Controllers/ClassifierController.j"
@import "Transformers/PngTransformer.j"
@import "Models/Glyph.j"


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
    @outlet ClassifierController classifierController;
}
- (void)awakeFromCib
{
    CPLogRegister(CPLogConsole);  // Adds stack trace info???
    [theWindow setFullPlatformWindow:YES];
    [WLRemoteLink setDefaultBaseURL:@""];
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [classifierController fetchClassifiers];
}
@end
