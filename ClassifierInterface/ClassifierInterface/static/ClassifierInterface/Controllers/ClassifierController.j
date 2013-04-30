@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    Classifier        theClassifier;  // Initialized by Open
    //CPArray classifierNames @accessors;  // Convenient array to have around
    @outlet CPWindow openClassifiersWindow;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet SaveClassifierDelegate  saveClassifierDelegate;
    @outlet CPArrayController   classifierArrayController;
    @outlet CPWindow newClassifierWindow;
    @outlet CPTextField newClassifierTextbox;
    @outlet CPTextField nameUsedLabel;  // TODO: implement red text when user enters a used name
    @outlet CPTextField statusLabel;

    @outlet     CPArrayController classifierGlyphArrayController;
    @outlet     CPCollectionView  cv;
                CPArray           imageList;
}
- (void)awakeFromCib
// applicationDidFinishLaunching didn't get called... weird
{
    // I used to set up actions of all of the buttons here, but then
    // I figured out how to do it in XCode:
    //  cancel buttons send an action to the windows' close function
    //  other buttons connect to classifierController functions.
    // I do the above two things in XCode now instead of here.
}
- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier list"];
}
- (void)fetchClassifiersDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
        // I get a warning for the previous line, not sure why...
        // ends up in CPURLConnection.j
    //[self classifierNames] = new CPArray();
    //[self setClassifierNames:new CPArray()];
    /*[self setClassifierNames:[]];
    for (var i = 0, classifiersCount = [classifiers count]; i < classifiersCount; ++i)
    {
        classifierNames[i] = [classifiers[i] name];
    }*/
}
- (@action)new:(CPMenuItem)aSender
{
    // TODO: consider displaying the classifier list in the New window.
    // (It might help the user to choose a name.)
    [newClassifierTextbox setObjectValue:[self suggestNameForNewClassifier]];
    [newClassifierWindow makeKeyAndOrderFront:aSender];
}
- (CPString)suggestNameForNewClassifier
/* Comes up with a suggestion for the user to name the new classifier.
Default suggestion is classifier0.
Expects fetchClassifiers to have been called.*/
{
    var i = 0,
        classifierCount = [[classifierArrayController arrangedObjects] count];
    //for (var i = 0, classifiersCount = [[self classifierNames] count]; i < classifiersCount; ++i)
    for (; i < classifierCount; ++i)
    {
        var suggestion = [[CPString alloc] initWithFormat:@"classifier%d", i];
        if (! [self classifierExists:suggestion])
        {
            return suggestion;
        }
    }
    return @"classifier" + CPString(classifierCount);
}
- (Boolean)classifierExists:(CPString)classifierName
/* Tells you if we have a classifier with the given name.
Doesn't go to the server... it relies on the previous call to fetchClassifiers*/
{
    var i = 0,
        //namesCount = [[self classifierNames] count];
        classifierArray = [classifierArrayController arrangedObjects],
        classifierCount = [classifierArray count];
    for (; i < classifierCount; ++i)
    {
        //if (classifierNames[i] === classifierName)
        if (classifierName === [classifierArray[i] name])
        {
            return true;
        }
    }
    return false;
}
- (@action)newClassifierTextboxKeyDown:(id)aSender
{
    // TODO: Red text when name is already in use.
    console.log("newClassifierTextboxKeyDown");
}
- (@action)createClassifier:(id)aSender
{
    // This is for the create button in the New Classifier window.
    // Check the user's classifier name then create.
    // TODO: Enter button from the textbox must call this function
    var newName = [newClassifierTextbox objectValue];
    if (! [self classifierExists:newName])
    {
        var classifier = [[Classifier alloc] init:newName];
        [classifierArrayController addObject:classifier];
        [classifier ensureCreated];
        [newClassifierWindow close];
    }
    else
    {
        // Do nothing!
        // TODO: Ensure that the label that writes in red, "Name already in use!"
        // hides/shows when the text box contains unused/used classifier names
        // (Then it will make sense for the 'Create' button to simply not respond)
    }

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
    @outlet ClassifierController classifierController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    [classifierController fetchClassifiersDidFinish:anAction];
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
