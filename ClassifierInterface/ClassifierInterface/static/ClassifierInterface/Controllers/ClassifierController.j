@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelButton;
    @outlet CPButton openButton;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet OpenClassifierDelegate  openClassifierDelegate;
    @outlet CPArrayController   classifierArrayController;
    @outlet CPArrayController   classifierGlyphArrayController;
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
    var openClassifier = [[classifierArrayController selectedObjects] objectAtIndex:0];
    [openClassifiersWindow close];

    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:[openClassifier pk]
                    delegate:openClassifierDelegate
                    message:@"loading a single classifier"];
}
- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier from home"];
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
    console.log([classifierArrayController contentArray]);
}
@end


@implementation OpenClassifierDelegate : CPObject
{
    Classifier      theClassifier;
    @outlet         CPArrayController       classifierGlyphArrayController;
    @outlet         CPTableView             classifierGlyphTableView;
}


- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    theClassifier = [[Classifier alloc] initWithJson:[anAction result]];

    console.log(theClassifier);

    [classifierGlyphArrayController bind:@"contentArray"
                                    toObject:theClassifier
                                    withKeyPath:@"glyphs"
                                    options:nil];

    // If I didn't want to do the link in XCode...
    //[classifierGlyphTableView bind:@"content"
    //                          toObject:classifierGlyphArrayController
    //                          withKeyPath:@""]

}

@end
