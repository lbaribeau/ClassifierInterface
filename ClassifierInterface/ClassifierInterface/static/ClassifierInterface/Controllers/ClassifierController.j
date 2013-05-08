@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    Classifier theClassifier;  // Initialized by Open
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
    @outlet SaveClassifierDelegate saveClassifierDelegate;

    @outlet CPArrayController classifierGlyphArrayController;
    @outlet CPCollectionView cv;
            CPArray imageList;
    @outlet CPTableView tv;

    @outlet CPArrayController symbolArrayController;

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
Doesn't go to the server... it relies on the previous call to fetchClassifiers.
Called by the newWindow when choosing a default name, or checking when create
was pressed.*/
{
    return [self arrayContains:[classifierArrayController contentArray] :classifierName];
    /*
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
    return false;*/
}
- (Boolean)arrayContains:(CPArray)array:(CPString)string
/* Looks for a string in an array and returns true if it finds it */
{
    var i = 0,
        array_count = [array count];
    for (; i < array_count; ++i)
    {
        if (array[i] === string)
        {
            return true;
        }
    }
    return false;
}
- (Boolean)reverseArrayContains:(CPArray)array:(CPString)string
/* Same as arrayContains except starts searching at the end. */
{
    var i = [array count];
    for (; i >= 0; --i)
    {
        if (array[i] === string)
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
        // The user will understand why the button did nothing because of the
        // red text that displays when classifierExists is true.
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
- (@action)openClassifier:(id)aSender
{
    // Read what is selected and get the glyphs of the corresponding classifier.
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

    [self _initializeSymbols];
}
- (void)_initializeSymbols
{
    // Loop through all glyphs and build an array of symbols.

    // (Shouldn't the server do this?  Yeah.  Even if there aren't
    // symbols in the xml, it should send them as JSON.  Then the client
    // can maintain the array any time things are changed.)
    // Well... that doesn't help because the list of symbols doesn't
    // tell you the counts.  Add that to the XML?  Or just not depend on
    // that?  I think the latter is superior.  (slower but more robust)
    // Either way we will need this code because we need to support the case
    // where the server doesn't have a symbol list.
    var i = 0,
        //glyphArray = [classifierGlyphArrayController contentArray],
        glyphArray = [theClassifier glyphs],
        glyphCount = [glyphArray count],
        symbolCounts = [CPDictionary dictionary],
        j = 0;

    [symbolArrayController setContent:[]];  // This is necessary if the user didn't 'close'
    for (; i < glyphCount; ++i)
    {
        var newSymbol = [glyphArray[i] idName];
        console.log("glyph i: " + i);
        console.log(glyphArray[i]);
        if (! [self reverseArrayContains:[symbolArrayController contentArray]:newSymbol])
        {
            console.log("true...");
            [symbolCounts setObject:1 forKey:newSymbol];
            [symbolArrayController addObject:newSymbol];
        }
        else
        {
            console.log("false...");
            var old_val = [symbolCounts objectForKey:newSymbol];
            [symbolCounts setObject:(old_val + 1) forKey:newSymbol];
        }
    }
    // TODO: add symbolArrayController to close

    // Hmmm... what I really want is a dict and the left column to contain the keys to the dict,
    // and the value is a count.  Can I trust a table view to read a dict?
    // What if I made an array by binding to glyphArray.idName.  Not really necessary: I could
    // already make a table with an array built from glyph.idName.  I need to make an array with
    // only one of each string. (symbolArrayController)  So, back to the dict idea.  I should be
    // able to bind the table content to the dict key and another column to the count.  I'd rather
    // put the count in brackets.  Add that to the todo list and do it with two columns.  No,
    // that's debt.  Just build an array of strings that is what I want.
    /*console.log([symbolArrayController contentArray]);
    console.log([symbolArrayController contentArray][0]);
    console.log([symbolArrayController contentArray][1]);
    console.log(symbolCounts);
    console.log([symbolCounts valueForKey:@"clef.c"]);*/

    // Now append (n) to the end of each string...
    var j = 0,
        symbolArray = [symbolArrayController contentArray],
        symbolCount = [symbolArray count];
    for (; j < symbolCount; ++j)
    {
        symbolArray[j] = [symbolArray[j] stringByAppendingFormat:@" (%d)", [symbolCounts objectForKey:symbolArray[j]]];
    }
    console.log([symbolArrayController contentArray]);
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

