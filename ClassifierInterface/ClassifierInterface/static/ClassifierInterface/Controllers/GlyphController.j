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
    var glyphs = [Classifier objectsFromJson:[anAction result]];
    //[glyphArrayController addObjects:glyphs];
    [glyphArrayController addObjects:[glyphs[0]]];
      // (I don't want to write XCode to handle an array of more than one yet)
}
@end
