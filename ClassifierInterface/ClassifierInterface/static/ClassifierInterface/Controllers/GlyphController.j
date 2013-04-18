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
    console.log("Fetched glyphs");
    var glyphs = [Classifier objectsFromJson:[anAction result]];
    [glyphArrayController addObjects:glyphs];
}
@end
