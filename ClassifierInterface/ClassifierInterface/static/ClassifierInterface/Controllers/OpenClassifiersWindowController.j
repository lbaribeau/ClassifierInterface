@implementation OpenClassifiersWindowController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelButton;
    @outlet CPButton openButton;
    // I shouldn't need the buttons as outlets because the window should have
    // them, but I can't find the getter...
}
- (void)awakeFromCib
// applicationDidFinishLaunching didn't get called
{
    [self tieCancelButtonToCloseFunction];
    [self tieOpenButtonToOpenClassifierFunction];
}
- (void)tieCancelButtonToCloseFunction
{
    [cancelButton setAction:@selector(closeWindow:)];
    [cancelButton setTarget:self];
}
- (void)tieOpenButtonToOpenClassifierFunction
{
    [openButton setAction:@selector(openClassifier:)];
    [openButton setTarget:self];
}
- (@action)closeWindow:(id)aSender
{
    [openClassifiersWindow close];
}
- (@action)openClassifier:(id)aSender
{
    console.log("Thank you for asking me to open, but I can't actually do that yet.");
    [openClassifiersWindow close];
    // I think that in order to write this function I'll need access to the
    // GlyphController.  Maybe OpenClassifiersWindowController
    // doesn't need to exist and all of this should be in ClassifierController.
    // Or, maybe it needs to be given to me.
    // Or, maybe I can return the glyphs to something that called me?
    // But, nothing called me... except the Classifer menu.
    // Actually, this should be merged with ClassifierController, because
    // ClassifierController populates the Open window's list.
}
@end
