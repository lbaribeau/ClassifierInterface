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
    CPData      glyphPng0   @accessors;
    CPData      glyphPng1   @accessors;
    //CPData      glyphPng2_2 @accessors;
}
+ (CPArray)remoteProperties  //Ratatosk
{
    return [
        //['pk',          'url']
        ['glyphPng0',   'glyph_png_0',      [[PngTransformer alloc] init], true],
        ['glyphPng1',   'glyph_png_1',      [[PngTransformer alloc] init], true]
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
        // Not sure that I need an array controller for a collection view... but I think so.
}
//init: TODO
- (void)fetchGlyphs
{
    console.log("Fetching glyphs");
    [WLRemoteAction schedule:WLRemoteActionGetType path:'/' delegate:self message:"Loading glyph from home"];
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    //debugger;
    console.log("Remote Action Did Finish");
    console.log([anAction result]);
    var glyphs = [GlyphPng objectsFromJson:[anAction result]]; // Not working yet.
    // The problem is that Ratatosk is expecting a list of Glyphs... but am just sending ONE object
    // with glyphs as fields (I rewrote GlyphPng to have another field... when I should have just
    // expected an array of two GlyphPngs)
    // So I need to make ratatosk expect a list with one "glyph" in it, where the "glyph" is an
    // object with two fields.
    // The problem was a syntax error in remoteProperties... Ratatosk couldn't get the objects from
    // JSON because init was failing
    console.log("Glyphs!")
    console.log(glyphs);
    [glyphArrayController addObjects:glyphs];
    //var png = [glyphs glyph_png_2]; //Do we even need ratatosk?  Yea, it will send the request.  But we don't need WPObject.
    // So, will the png be in JSON?  Andrew said that it could be put into the template, i'll go look that up.
    // (what i mean is, instead of it being like images on web pages which are get separately, it will be
    // encoded inline into the html)
    // Ok.  It is a JSON response.
    // I think I need to make a WLRemoteObject.  Even though I didn't have a django model on the other end,
    // the JSON I made can be turned into an object.
    //[glyphController addObjects:png];

}
@end


