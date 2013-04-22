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
//- (@action)newClassifier:(id)aSender
//{
//    var classifier = [[Project alloc] init];
//    [projectArrayController addObject:project];
//    [project ensureCreated];    // One-shot Ratatosk call to update the server side.
                                // (you could schedule it if you wanted but it's simpler to
                                // do it in one line if you can.)
//}
- (@action)openClassifier:(id)aSender
{
    // Read what is selected and get the glyphs of the corresponding
    // classifier.
    console.log("Thank you for asking me to open, but I can't actually do that yet.");
    [openClassifiersWindow close];
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
