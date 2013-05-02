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
@import "Delegates/SymbolOutlineDelegate.j"
@import "Transformers/PngTransformer.j"
@import "Models/Glyph.j"


@implementation AppController : CPObject
{
    @outlet CPWindow theWindow;
    @outlet CPTextField symbolNameEntry;
    @outlet SymbolOutlineDelegate symbolOutline;
    CPCookie sessionID;
    CPCookie CSRFToken;
}
- (void)awakeFromCib
{
    CPLogRegister(CPLogConsole);  // Adds stack trace info???
    sessionID = [[CPCookie alloc] initWithName:@"sessionid"];
    CSRFToken = [[CPCookie alloc] initWithName:@"csrftoken"];
    [[WLRemoteLink sharedRemoteLink] setDelegate:self];
    [theWindow setFullPlatformWindow:YES];
    [WLRemoteLink setDefaultBaseURL:@""];
    //[symbolOutline applicationDidFinishLaunching:null];
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{

}
- (void)remoteLink:(WLRemoteLink)aLink willSendRequest:(CPURLRequest)aRequest withDelegate:(id)aDelegate context:(id)aContext
{
    switch ([[aRequest HTTPMethod] uppercaseString])
    {
        case "POST":
        case "PUT":
        case "PATCH":
        case "DELETE":
            [aRequest setValue:[CSRFToken value] forHTTPHeaderField:"X-CSRFToken"];
    }
}
@end
