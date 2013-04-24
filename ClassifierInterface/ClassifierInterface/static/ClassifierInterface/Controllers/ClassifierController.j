@import "../Models/Classifier.j"
@import "../Transformers/GlyphTransformer.j"  // (Debugging)

@implementation ClassifierController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelOpenButton;
    @outlet CPButton openButton;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet OpenClassifierDelegate  openClassifierDelegate;
    @outlet CPArrayController   classifierArrayController;
    @outlet CPWindow newClassifierWindow;
    @outlet CPButton cancelNewButton;
    @outlet CPButton createClassifierButton;
}
- (void)awakeFromCib
// applicationDidFinishLaunching didn't get called
{
    //[cancelOpenButton setAction:@selector(closeOpenWindow:)];
    [cancelOpenButton setAction:@selector(close)];
    [cancelOpenButton setTarget:openClassifiersWindow];
    [openButton setAction:@selector(openClassifier:)];
    [openButton setTarget:self];
    [cancelNewButton setAction:@selector(close)];
    [cancelNewButton setTarget:newClassifierWindow];
}
//- (@action)newClassifier:(id)aSender
//{
//    var classifier = [[Classifier alloc] init];
//    [projectArrayController addObject:project];
//    [project ensureCreated];    // One-shot Ratatosk call to update the server side.
                                // (you could schedule it if you wanted but it's simpler
                                // to do it in one line if you can.)
//}
- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier list"];
}
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

    // TODO: make this function available by double clicking in the open window
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
        // I get a warning for the previous line, not sure why...
        // ends up in CPURLConnection.j
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

    console.log("THE CLASSIFIER!");
    console.log(theClassifier);

    [classifierGlyphArrayController bind:@"contentArray"
                                    toObject:theClassifier
                                    withKeyPath:@"glyphs"
                                    options:nil];

    // If I didn't want to do the link in XCode...
    //[classifierGlyphTableView bind:@"content"
    //                          toObject:classifierGlyphArrayController
    //                          withKeyPath:@""]

    console.log("Calling new transformer function");
    [[GlyphTransformer alloc] reverseTransformedValue:[theClassifier glyphs]];

}

@end
