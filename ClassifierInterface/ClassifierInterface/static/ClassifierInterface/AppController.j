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
@import "Controllers/GlyphController.j"
@import "Controllers/ClassifierController.j"
@import "Transformers/PngTransformer.j"


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
    @outlet GlyphController glyphController;
    @outlet ClassifierController classifierController;
}
- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
    [WLRemoteLink setDefaultBaseURL:@""];
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    //[glyphController fetchGlyphs];
    [classifierController fetchClassifiers];
}
@end
