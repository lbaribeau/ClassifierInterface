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

@implementation AppController : CPObject
{
    CPWindow    theWindow;
    @outlet CPObject    glyphController;
}
- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
    [WLRemoteLink setDefaultBaseURL:@""];
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [glyphController fetchGlyphs];
}
@end

/*** MODEL ***/
@implementation GlyphPng : WLRemoteObject
{
    //CPString    pk          @accessors;
    CPData      glyphPng   @accessors;
}
+ (CPArray)remoteProperties  //Ratatosk
{
    return [
        //['pk',          'url'],
        ['glyphPng',   'glyph_png',      [[PngTransformer alloc] init], true],
    ];
}
- (CPString)remotePath  //Ratatosk
{
    // Refactor 'GlyphPng' to be a 'classifier' and give it some getGlyphs functions
    // Then do the URLs... remote URL is /classifier/uuid.
    /*if ([self pk])
    {
        return @"/[self pk];
    }
    else
    {
        return @"/classifiers/";
    }*/
    return @"/";
}
@end


@implementation PngTransformer : CPObject //See WLRemoteTransformers.j in Ratatosk
{

}
+ (BOOL)allowsReverseTransformation
{
    return NO;
}
+ (Class)transformedValueClass
{
    return [CPData class];
}
- (id)transformedValue:(id)value
{
    return [CPData dataWithBase64:value];
}
@end

/*** CONTROLLER ***/
/* The thing that knows how to get glyphs */
@implementation GlyphController : CPObject
{
    @outlet     CPArrayController   glyphArrayController;
}
//init: TODO
- (void)fetchGlyphs
{
    console.log("Fetching glyphs");
    [WLRemoteAction schedule:WLRemoteActionGetType path:'/' delegate:self message:"Loading glyph from home"];
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    console.log("Remote Action Did Finish");
    console.log([anAction result]);
    var glyphs = [GlyphPng objectsFromJson:[anAction result]];
    console.log(glyphs);
    //[glyphArrayController addObjects:glyphs];
    [glyphArrayController addObjects:[glyphs[0]]];
      // (I don't want to write XCode to handle an array of more than one yet)
    console.log(glyphArrayController);
    //debugger;
}
@end
