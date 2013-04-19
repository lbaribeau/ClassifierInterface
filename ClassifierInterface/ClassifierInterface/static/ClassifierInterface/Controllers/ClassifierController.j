@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelButton;
    @outlet CPButton openButton;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
}
- (void)awakeFromCib
// applicationDidFinishLaunching didn't get called
{
    [cancelButton setAction:@selector(closeWindow:)];
    [cancelButton setTarget:self];
    [openButton setAction:@selector(openClassifier:)];
    [openButton setTarget:self];
}
- (@action)closeWindow:(id)aSender
{
    [openClassifiersWindow close];
}
- (@action)openClassifier:(id)aSender
{
    // Read what is selected and get the glyphs of the corresponding
    // classifier.
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
// Ok.  So we merged to ClassifierController because so far everything we've
// done is for the OpenClassifiersWindow and it should all be in one
// controller.  Maybe 'New' and 'Save' will use the same controller...
// but maybe ClassifierController will have to be renamed to OpenClassifiers
// controller and 'new' and 'save' will get their own controllers.  I prefer
// the former option.

- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier from home"];
    // Using self as the delegate would be cleaner but I may in the future
    // have to send more requests so I may as well keep this delegate class
    // and may need to repeat the pattern in the future.
    // But, isn't another kind of request a good excuse for a diffierent
    // controller?  Or should glyphController be merged with this one?
    // Unless getGlyphs is put into the serverside model, I may as well
    // keep glyphs (along with all the other XML) separate from the classifier
    // model.  Now, in Rodan, only ProjectController and WorkflowController
    // don't use self as the delegate, and both of those use self for one
    // call and a delegate for the next.
    // So... well... I'll just leave that delegate for now.
}
@end

@implementation LoadClassifiersDelegate : CPObject
{
    @outlet CPArrayController classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
}
@end
