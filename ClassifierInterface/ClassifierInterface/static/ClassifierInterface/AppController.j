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
@import "Controllers/OpenClassifiersWindowController.j"
@import "Transformers/PngTransformer.j"


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
    @outlet GlyphController glyphController;
    @outlet ClassifierController classifierController;
    @outlet OpenClassifiersWindowController openClassifiersWindowController;
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
    [classifierController debugPrintWindow];  // Works
    //[openClassifiersWindowController init];  // 2nd call to init?
                                             // Maybe just giving the instance to AppController will help
    [openClassifiersWindowController debugPrintWindow];
    //[openClassifiersWindowController helloWorld];
    [openClassifiersWindowController tieCancelButtonToCloseFunction];
}
- (void)closeWindow
{
    console.log("Cancel button was pressed.");
    //[openClassifiersWindow close];
    //[openClassifiersWindow [cancelButton setAction:@selector(closeWindow:)]];
}
@end
