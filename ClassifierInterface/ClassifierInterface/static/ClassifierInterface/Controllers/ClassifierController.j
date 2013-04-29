@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    Classifier        theClassifier;
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton openButton;
    @outlet CPButton cancelOpenButton;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet SaveClassifierDelegate  saveClassifierDelegate;
    @outlet CPArrayController   classifierArrayController;
    @outlet CPWindow newClassifierWindow;
    @outlet CPButton createClassifierButton;
    @outlet CPButton cancelNewButton;
    @outlet CPTextField statusLabel;

    @outlet     CPArrayController classifierGlyphArrayController;
    @outlet     CPCollectionView  cv;
                CPArray           imageList;
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
                    delegate:self
                    message:@"loading a single classifier"];

    // TODO: make this function available by double clicking in the open window
}
- (void)remoteActionDidFinish:(WLRemoteAction)anAction
/* Open operation just finished: server sent us a full classifier */
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

    /* Uncomment these lines and make the 'Saved Collection View' window visible at launch
    [self setUpCollectionView];
    console.log(cv);
    */
}


- (@action)writeSymbolName:(CPTextField)aSender
/* Write the new symbol for each selected glyph */
{
    var newName = [aSender stringValue],
        selectedObjects = [classifierGlyphArrayController selectedObjects];
    console.log("Writing " + [selectedObjects count] + " glyph(s).");
    for (var i = 0; i < [selectedObjects count]; ++i)
    {
        [selectedObjects[i] writeSymbolName:newName];
        console.log(selectedObjects[i]);
    }
}
- (@action)save:(CPMenuItem)aSender
/* Save glyphs to xml on server */
{
    if (theClassifier)
    {
        console.log("In save");
        console.log(theClassifier);
        //console.log([theClassifier pk]);
        //[WLRemoteAction schedule:WLRemoteActionPutType
        //                path:[theClassifier pk]
        //                delegate:SaveClassifierDelegate
        //                message:@"Save classifier"];
        //[theClassifier ensureCreated];
        // patch and ensure saved
        // have patch contain the changed fields
        [theClassifier makeAllDirty];
        //[theClassifier makeDirtyProperty:@"id_name"];
        [theClassifier ensureSaved];
        [statusLabel setStringValue:@"Saved."];
    }
    else
    {
        // TODO: Error checking: Grey out the Save function on the menu until something
        // is open.
        [statusLabel setStringValue:@"Save failed: There is no open file."];
    }
}

- (void)setUpCollectionView
/* This function isn't currently being used as I am going with a table view for now */
{
    [cv setAutoresizingMask:CPViewWidthSizable];
    [cv setMinItemSize:CGSizeMake(100, 100)];
    [cv setMaxItemSize:CGSizeMake(100, 100)];
    [cv setDelegate:self];
    [cv setSelectable:YES];

    var itemPrototype = [[CPCollectionViewItem alloc] init];
    [itemPrototype setView:[[PhotoView alloc] initWithFrame:CGRectMakeZero()]];
    [cv setItemPrototype:itemPrototype];


    imageList = [];
    var theClassifierGlyphs = [theClassifier glyphs];
    for (var i = 0; i < theClassifierGlyphs.length; i++)
    {
        var glyphImageData = [theClassifierGlyphs[i] pngData],
            glyphImage = [[CPImage alloc] initWithData:glyphImageData];
        imageList[i] = glyphImage;
    }
    [cv setContent:imageList];

    // I would prefer if I didn't have to make a pile of CPImages but there's no other way
    // with the collection view from what I can tell.  Maybe I can rewrite the
    // glyph model?  It could be done with parallel arrays, and glyph.pngData would
    // point to an image data in a parallel image array.  I don't even know if you can
    // get the data back out of an image... And do I even need the functionality of
    // a collection view???  I had better put this aside and start working on 'Save' with
    // the table view.
}

@end




@implementation LoadClassifiersDelegate : CPObject
{
    @outlet ClassifierArrayController classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
        // I get a warning for the previous line, not sure why...
        // ends up in CPURLConnection.j
}
@end
/*
@implementation OpenClassifierDelegate : CPObject
{
    @outlet     ClassifierController classifierController;

}
- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    [classifierController openActionDidFinish:anAction];
}
@end
*/
@implementation SaveClassifierDelegate : CPObject
{
    @outlet     ClassifierController classifierController;
}
- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    // What does the response look like?
    // TODO: write some kind of validation or the response here.
    [classifierController saveActionDidFinish:anAction];
}
@end

// Refactoring everything into classifierController because otherwise OpenDelegate
// did everything.  To implement Save, OpenDelegate would have to give theClassifer
// to classifierController.  It's better for classifierController should
// definitely have theClassifier, so openDelegate doesn't need it.
// Since I was doing it to open I did it to Load as well.  Maybe that wasn't necessary.
// We'll see if this pattern sticks.


@implementation PhotoView : CPImageView
/*
PhotoView implements functions required by the collection view
(setSelected and setRepresented)
see http://280north.com/learn/tutorials/scrapbook-tutorial-2/
*/
{
    CPImageView _imageView;
}
- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [CPColor grayColor] : nil];
}
- (void)setRepresentedObject:(id)anObject
{
    if (!_imageView)
    {
        var frame = CGRectInset([self bounds], 5.0, 5.0);

        _imageView = [[CPImageView alloc] initWithFrame:frame];

        [_imageView setImageScaling:CPScaleProportionally];
        [_imageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self addSubview:_imageView];
    }

    [_imageView setImage:anObject];
}
@end

/*
    Trying to get CV to work with bindings:
    console.log("CollectionView:");
    console.log(cv);
    console.log([cv itemPrototype]);
    console.log([[cv itemPrototype] view]);
    console.log([[[cv itemPrototype] view] image]);  // good selector, returns null
    // console.log([[[cv itemPrototype] view] representedObject]);  bad selector
    //console.log([[[cv itemPrototype] view] data]);  // No CPImageView data
    // console.log([[[cv itemPrototype] view] view]);  // No CPImageView view
    console.log([[[[cv itemPrototype] view] image] data]);  // null null
*/
