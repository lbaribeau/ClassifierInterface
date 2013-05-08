@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    Classifier        theClassifier;  // Initialized by Open
    @outlet CPArrayController classifierArrayController;

    @outlet CPWindow newClassifierWindow;
    @outlet CPButton createButton;
    @outlet CPTextField newClassifierTextfield;
    @outlet CPTextField nameUsedLabel;
    @outlet CPTextField statusLabel;
    @outlet CPWindow openClassifierWindow;
    @outlet CPButton openButton;
    @outlet InitNewFetchClassifiersDelegate initNewFetchClassifiersDelegate;
    @outlet NewClassifierTextfieldDelegate newClassifierTextfieldDelegate;
    @outlet InitOpenFetchClassifiersDelegate initOpenFetchClassifiersDelegate;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet SaveClassifierDelegate  saveClassifierDelegate;

    @outlet     CPArrayController classifierGlyphArrayController;
    @outlet     CPCollectionView  cv;
                CPArray           imageList;
    @outlet     CPTableView       tv;
}

// applicationDidFinishLaunching didn't get called... weird
// Seems to only work on AppController.
- (void)awakeFromCib
{
    [newClassifierTextfield setDelegate:newClassifierTextfieldDelegate];
        // (Required for red warning text if user enters a classifier name that's already used.)
    [newClassifierWindow setDefaultButton:createButton];
    [openClassifierWindow setDefaultButton:openButton];

    // I used to set up actions of all of the buttons here, but then
    // I figured out how to do it in XCode:
    //  cancel buttons send an action to the windows' close function
    //  other buttons connect to classifierController functions.
}
- (@action)new:(CPMenuItem)aSender
{
    // TODO: consider displaying the classifier list in the New window.
    // (It might help the user to choose a name.)
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:initNewFetchClassifiersDelegate
                    message:"Loading classifier list"];
}
- (void)initNewFetchClassifiersDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController setContent:classifiers];
    [newClassifierTextfield setStringValue:[self suggestNameForNewClassifier]];
    [self updateNameUsedLabel];
    [newClassifierWindow makeKeyAndOrderFront:null];
}
- (CPString)suggestNameForNewClassifier
/* Comes up with a suggestion for the user to name the new classifier.
Default suggestion is classifier0.
Expects classifierArrayController to have been populated.*/
{
    var i = 0,
        classifierCount = [[classifierArrayController contentArray] count];
    for (; i < classifierCount; ++i)
    {
        var suggestion = [[CPString alloc] initWithFormat:@"classifier%d", i];
        if (! [self classifierExists:suggestion])
        {
            return suggestion;
        }
    }
    return @"classifier" + classifierCount.toString();
}
- (Boolean)classifierExists:(CPString)classifierName
/* Tells you if we have a classifier with the given name.
Doesn't go to the server... it relies on the previous call to fetchClassifiers*/
{
    var i = 0,
        classifierArray = [classifierArrayController contentArray],
        classifierCount = [classifierArray count];
    for (; i < classifierCount; ++i)
    {
        if (classifierName === [classifierArray[i] name])
        {
            return true;
        }
    }
    return false;
}
- (void)updateNameUsedLabel
{
    if ([self classifierExists:[newClassifierTextfield stringValue]])
    {
        [nameUsedLabel setHidden:NO];
    }
    else
    {
        [nameUsedLabel setHidden:YES];
    }
}
- (@action)open:(CPMenuItem)aSender
{
    [WLRemoteAction schedule:WLRemoteActionGetType
            path:'/classifiers/'
            delegate:initOpenFetchClassifiersDelegate
            message:"Loading classifier list for open"];
}
- (void)initOpenFetchClassifiersDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController setContent:classifiers];
    [openClassifierWindow makeKeyAndOrderFront:null];
}
- (@action)createClassifier:(id)aSender
{
    // This is for the create button in the New Classifier window.
    // Check the user's classifier name then create.
    // TODO: Enter button from the textbox must call this function
    var newName = [newClassifierTextfield stringValue];
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
    [openClassifierWindow close];

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

    [self setUpCollectionView];
    console.log(cv);

}
- (@action)writeSymbolName:(CPTextField)aSender
/* Write the new symbol for each selected glyph */
{
    var newName = [aSender stringValue],
        selectedObjects = [classifierGlyphArrayController selectedObjects];
    for (var i = 0; i < [selectedObjects count]; ++i)
    {
        [selectedObjects[i] writeSymbolName:newName];
    }
    [theClassifier makeAllDirty];
    //[theClassifier makeDirtyProperty:@"id_name"];
    [theClassifier ensureSaved];
}
/*
- (@action)save:(CPMenuItem)aSender
// Save glyphs to xml on server
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

        [theClassifier ensureSaved];
        [statusLabel setStringValue:@"Saved."];
    }
    else
    {
        // TODO: Error checking: Grey out the Save function on the menu until something
        // is open.
        [statusLabel setStringValue:@"Cannot save, there is no open file."];
    }
}*/
- (@action)close:(CPMenuItem)aSender
{
    if (theClassifier)
    {
        if ([theClassifier isDirty])
        {
            [theClassifier ensureSaved];
            [statusLabel setStringValue:@"Saved and closed."];
        }
        else
        {
            [statusLabel setStringValue:@"Closed."];
        }
        theClassifier = null;
        // Careful... should I repeat fetch here?  Shouldn't fetch be done when New or Open
        // is called?  Try it out.
        [classifierGlyphArrayController setContent:[]];
    }
}



- (void)fetchClassifiers
// Fetches classifiers and assigns them to classifierArrayController's content.
// NOTE: No longer used!
// I am opting for more controlled versions of this functionality.
// When I do a fetch, generally want control of the callback.
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier list for new"];
}
- (void)fetchClassifiersDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController setContent:classifiers];
        // I get a warning for the previous line, not sure why...
        // ends up in CPURLConnection.j
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
        console.log("i is " + i);
        var glyphImageData = [theClassifierGlyphs[i] pngData],
            glyphImage = [[CPImage alloc] initWithData:glyphImageData];
        imageList[i] = glyphImage;
    }
    [cv setContent:imageList];
    [cv setBackgroundColor:[CPColor blueColor]];
    [tv setBackgroundColor:[CPColor clearColor]];
    //[tv setHeadverView:cv];

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

@implementation InitNewFetchClassifiersDelegate : CPObject
{
    @outlet ClassifierController classifierController;
}
- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    [classifierController initNewFetchClassifiersDidFinish:anAction];
}
@end

@implementation InitOpenFetchClassifiersDelegate : CPObject
{
    @outlet ClassifierController classifierController;

}
- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    [classifierController initOpenFetchClassifiersDidFinish:anAction];
}
@end

@implementation NewClassifierTextfieldDelegate : CPObject
{
    @outlet ClassifierController classifierController;
}
- (void)controlTextDidChange:(CPNotification)aNotification
{
    [classifierController updateNameUsedLabel];
}
@end

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

