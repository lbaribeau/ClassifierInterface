@import "../Views/PhotoView.j"
@import "../Views/ViewWithObjectValue.j"
@import "../Models/SymbolCollection.j"
@import "../Models/Classifier.j"

@implementation ClassifierTableViewDelegate : CPObject
{
    @outlet CPArrayController symbolCollectionArrayController;
    @outlet CPWindow theWindow;
    // CPCollectionView cv;  // used to print the cv after everything's displayed, in order to see its dimensions
    int headerLabelHeight @accessors;
    int photoViewInset @accessors;
    CPCollectionView gCollectionView @accessors; // Debug
}
- (void)init
{
    self = [super init];
    [self setHeaderLabelHeight:20];
    [self setPhotoViewInset:10];
    // [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentBoundsDidChange:) name:CPViewBoundsDidChangeNotification object:self.scrollView.contentView];
    // For now, add the label...
    return self;
}

- (void)initializeSymbolCollections:(Classifier)aClassifier
{
    var i = 0,
        glyphs = [aClassifier glyphs],
        glyphs_count = [[aClassifier glyphs] count],
        symbolCollectionArray = [[CPMutableArray alloc] init];
    while (i < glyphs_count)
    // Assume the glyphs are sorted by id name.
    // Make an array for each id name.
    {
        var symbolCollection = [[SymbolCollection alloc] init],
            symbolName = [glyphs[i] idName],
            maxRows = 0,
            maxCols = 0;
        [symbolCollection setSymbolName:symbolName];
        for (; i < glyphs_count && [glyphs[i] idName] == symbolName; ++i)
        {
            if ([glyphs[i] nRows] > maxRows)
                maxRows = [glyphs[i] nRows];
            if ([glyphs[i] nCols] > maxCols)
                maxCols = [glyphs[i] nCols];
            // [symbolCollection addImage:[[CPImage alloc] initWithData:[glyphs[i] pngData]]];
            [symbolCollection addGlyph:glyphs[i]];
            // Maybe maxRows and maxCols aren't necessary?  True, but regardless it's good to assemble them now.
        }
        [symbolCollection setMaxRows:maxRows];
        [symbolCollection setMaxCols:maxCols];
        [symbolCollectionArray addObject:symbolCollection];
    }
    // var symbolCollectionArrayController = [[CPArrayController alloc] init];
    // symbolCollectionArrayController = [[CPArrayController alloc] init];
    [symbolCollectionArrayController setContent:symbolCollectionArray];
}
- (CPView)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Return a view for the TableView to use a cell of the table.
{
    var aView = [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
    return aView;
}
- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Set up the view to display.  (Delegate method.)
// (Note: I do things in this function so that I have access to objectValue... which I don't in viewForTableColumn.)
{
    console.log("---willDisplayView---");
    var symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:aTableColumn row:aRow],
        label = [[CPTextField alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth([aView bounds]), [self headerLabelHeight])];
    [label setStringValue:[symbolCollection symbolName]];
    [label setFont:[CPFont boldSystemFontOfSize:16]];
    [label setAutoresizesSubviews:NO];
    [label setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin];
    [aView addSubview:label];

    // // var rowHeight = CGRectGetHeight([aView frame]);  // 2:04
    // // The tableView may not be happy if I set the view height here.
    // // [aView setFrame:CGRectMake(CGRectGetMinX([aView frame]), CGRectGetMinY([aView frame]), CGRectGetWidth([aView frame]), 1)];  // 2:04
    // var cvArrayController = [[CPArrayController alloc] init],  // TODO: This will need to be more scoped when implementing selections
    //     cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayController parentView:aView row:aRow];
    // // [aView setFrame:CGRectMake(CGRectGetMinX([aView frame]), CGRectGetMinY([aView frame]), CGRectGetWidth([aView frame]), rowHeight)];  // 2:04
    // // 2:04 code: seems like the row is big enough but the coll view gets cut off... trying to build cv into a smaller view

    var parentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [aView setAutoresizesSubviews:NO];
        //It's driving me bonkers: why doesn't the label get pinned to the top of aView upon resize???  Use the ViewForFirstRow button to debug.
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [parentView setAutoresizesSubviews:NO];  // also gets set by _makeCollectionViewForTableView
    [parentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [aView addSubview:parentView];
    [parentView setFrame:CGRectMake(0, [self headerLabelHeight], CGRectGetWidth([aView bounds]), CGRectGetHeight([aView bounds]) - [self headerLabelHeight])];
    var cvArrayController = [[CPArrayController alloc] init],
        cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayController parentView:parentView row:aRow];
    // [cv setFrame:CGRectMake(0, CGRectGetHeight([label bounds]), CGRectGetWidth([cv bounds]), CGRectGetHeight([cv bounds]))];  // Hmm.. this was to move the cv down, so I shouldn't need it

    // Not sure why the following is here: commenting to try to prevent resizing
    // [cv setFrame:CGRectMake(0, 0, CGRectGetWidth([cv bounds]), CGRectGetHeight([cv bounds]))];  // Getting rid of borders to try to measure the spacing that the coll view adds.
        // Does nothing...
    // [cv setBounds:CGRectMake(0,0,CGRectGetWidth([cv bounds]),CGRectGetWidth([aView bounds]),CGRectGetHeight([aView bounds]))];

    // console.log("---Last ever access (in willDisplayView) checking aView:");
    // [self recheck_heights:aView];  // Interesting... I can get 417 out at this point.
    // console.log("number of rows in the table view:" + [aTableView numberOfRows]);
    // Try only resizing the collection view (because the darn label repositions).
    // Promising, but the coll view still sucks
}

- (void)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// (Data source method)
{
    return [symbolCollectionArrayController arrangedObjects][aRow]; // (Ignoring the column... the table has only one column)
}
- (void)numberOfRowsInTableView:(CPTableView)aTableView
// (Data source method)
{
    return [[symbolCollectionArrayController contentArray] count];
}
- (void)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
// Returns the height of a specified row.  (Delegate method.)
{
    // // return CGRectGetHeight([_cv bounds]) + 20;
    // console.log("In heightOfRow...")
    // console.log("_cv frame:");
    // console.log([_cv frame]);
    // console.log("_cv bounds:");
    // console.log([_cv bounds]);
    // console.log("...exiting heightOfRow");

    // // var retval = CGRectGetHeight([_cv bounds]);
    // // retval = 268;
    // // console.log("returning " + retval)
    // // return retval;

    // // (Note... need 3 rows of glyphs for the following numbers.)
    // // Ok, the collection view is being dumb.  Ask the last image where its frame is... and calculate the row height as the distance between the bottom of that
    // // frame and the top of the collection view.
    // //return 268;
    // // Maybe the collection view redraws, so the height I'm getting isn't the final height.
    // // Gwargh... so the collection view gets its height wrong.  Maybe I can check the end of the frame of the last item in the collection view
    // // use subviews[count - 1] to get at it.
    // //   - Avoids another O(n) search through glyph images by assuming that the last item is the bottom right image.
    // //   - We'll see pretty quickly if that assumption is wrong.
    // // Let's console log 268 (the height that we want) whereas 258 is the incorrect height
    // // Problem: there is still cutoff whenever we increase the row height!  (Right?  YES!  WRONG!)
    // var bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame];
    // var y_of_bottom_image = CGRectGetMaxY(bottom_image_frame);  // Thought I'd do origin plus height but maybe this'll do it
    // console.log("y_of_bottom_image: " + y_of_bottom_image);
    // console.log("second last image: " + CGRectGetMaxY([[_cv subviews][[[_cv subviews] count] - 1] frame]));
    // // return y_of_bottom_image;  // returns 408 when the answer is 417.  It MUST be redrawing... maybe I can shut off autoresize again.
    //   // Nevermind max y... use the numbers I see
    // var y_of_bottom_image = CGRectGetMinY(bottom_image_frame);
    // console.log("Should be 283: " + y_of_bottom_image);  //273
    // var height_of_bottom_image = CGRectGetHeight(bottom_image_frame);
    // console.log("Should be 134: " + height_of_bottom_image);  //129
    // // return 402;
    // // return y_of_bottom_image + height_of_bottom_image;
    // // Perhaps aView is different because of the predetermined row height.
    // // I suppose that's possible.  What are my options.  I could iterate (dumb) I could add a fudge factor... that would depend on the number of rows...
    // // I could see how bad the problem is with hundreds of punctums (it could be good and could be bad)
    // // (It seems that using the bottom of the last image IS a little better... better test that out.)
    // // return CGRectGetHeight([_cv frame]);  // Yes indeed, very true  (this is worse)
    // // It's like the algorithm is one iteration better... and then the problem occurs when there's three rows of symbols instead of two.  Weird.
    // // So the numbers are 387, 402, 417... intervals of 15.  So I need to add 15 for each row of symbols.
    // // Remember that the problem's worse when headers are in.
    // // Ummm... Maybe I can set the properties of bView and/or do some iterations of height-reading.  Maybe I can trigger the recalculation somehow (adding to another view?)
    // // Recall: 1st 'iteration' reading _cv's frame and 2nd is reading the bottom of the image.
    // // Try setting the frame of the _cv and then seeing where the bottom image goes.
    // // 417 is what we want for the 3rd row but who knows how far the rabbit hole goes.
    // // If I can come up with an iterative algorithm, maybe I can figure when to stop by monitoring the output.
    // [self recheck_heights:dummyView];
    // // [dummyView setFrame:[dummyView frame]];  // maybe this'll redraw
    // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]), CGRectGetMinY([dummyView frame]),
    //                                CGRectGetWidth([dummyView frame]), y_of_bottom_image + height_of_bottom_image)];
    // [[dummyView subviews][0] removeFromSuperview];
    // ac = [[CPArrayController alloc] init];
    // [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow];
    // [self recheck_heights:dummyView];
    // var _cv = [dummyView subviews][0];
    // // return CGRectGetMaxY([[_cv subviews][[[_cv subviews] count] - 1] frame]);  // Works for 3 rows.
    // // Now try adding even MORE glyphs and watch it clip
    // // Ok... so try what I wrote down.
    // // Set aView height to 1, build the cv, add the cv to that view.
    // // (however the cv needs to be in the view to build itself.)
    // // Just to break new ground, iterate again!  Copy code!
    // bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame];
    // y_of_bottom_image = CGRectGetMinY(bottom_image_frame);
    // height_of_bottom_image = CGRectGetHeight(bottom_image_frame);
    // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]), CGRectGetMinY([dummyView frame]),
    //                                CGRectGetWidth([dummyView frame]), y_of_bottom_image + height_of_bottom_image)];
    // [[dummyView subviews][0] removeFromSuperview];
    // ac = [[CPArrayController alloc] init];
    // [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow];
    // [self recheck_heights:dummyView];
    // // Seems like the row is big enough but the coll view gets cut off.

    // // Now get the 4th row working
    // // _cv = [dummyView subviews][0];
    // // bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame];
    // // y_of_bottom_image = CGRectGetMinY(bottom_image_frame);
    // // height_of_bottom_image = CGRectGetHeight(bottom_image_frame);
    // // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]), CGRectGetMinY([dummyView frame]),
    // //                                CGRectGetWidth([dummyView frame]), y_of_bottom_image + height_of_bottom_image)];
    // // [[dummyView subviews][0] removeFromSuperview];
    // // ac = [[CPArrayController alloc] init];
    // // [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow];
    // // [self recheck_heights:dummyView];
    // // // return y_of_bottom_image + height_of_bottom_image;

    // // //5th
    // // _cv = [dummyView subviews][0];
    // // bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame];
    // // y_of_bottom_image = CGRectGetMinY(bottom_image_frame);
    // // height_of_bottom_image = CGRectGetHeight(bottom_image_frame);
    // // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]), CGRectGetMinY([dummyView frame]),
    // //                                CGRectGetWidth([dummyView frame]), y_of_bottom_image + height_of_bottom_image)];
    // // [[dummyView subviews][0] removeFromSuperview];
    // // ac = [[CPArrayController alloc] init];
    // // [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow];
    // // [self recheck_heights:dummyView];
    // // return y_of_bottom_image + height_of_bottom_image;
    // // Ok.  I'm going ahead with this REDICULOUS algorithm.  I need to iterate this height calculation X times, and X is the number of rows in the collection view.
    // // X is numGlyphs*widthOfGlyph / widthOfTable

    // Calculate 5 for the 3rd row (glyph3)

    var ac = [[CPArrayController alloc] init],
        dummyView = [[CPView alloc] initWithFrame:CGRectMake(1,1,CGRectGetWidth([aTableView bounds]),1)],
        _cv = [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow],
        symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
        glyphWidth = [symbolCollection maxCols] + (2 * [self photoViewInset]),
        glyphCount = [[symbolCollection glyphList] count],
        tableWidth = CGRectGetWidth([aTableView bounds]),
        number_of_rows_in_collection_view = Math.ceil((glyphWidth * glyphCount) / tableWidth),
        bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame],
        // y_of_bottom_image = CGRectGetMinY(bottom_image_frame),
        // height_of_bottom_image = CGRectGetHeight(bottom_image_frame),
        bottom_of_last_image = CGRectGetMaxY(bottom_image_frame),
        // bottom_of_last_photoview = CGRectGetMaxY(bottom_image_frame) + [self photoViewInset],
        // cell_spacing_neglected_by_collection_view = bottom_of_last_image;  //70
        cell_spacing_neglected_by_collection_view = bottom_of_last_image - CGRectGetHeight([_cv bounds]);  //70
        // cell_spacing_neglected_by_collection_view = bottom_of_last_photoview - CGRectGetHeight([_cv bounds]);
    // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]), CGRectGetMinY([dummyView frame]),
    //                                CGRectGetWidth([dummyView frame]), y_of_bottom_image + height_of_bottom_image)];
    // [dummyView setFrame:CGRectMake(CGRectGetMinX([dummyView frame]),
    //                                CGRectGetMinY([dummyView frame]),
    //                                CGRectGetWidth([dummyView frame]),
    //                                CGRectGetHeight([_cv bounds]) + cell_spacing_neglected_by_collection_view * number_of_rows_in_collection_view)];
    // [[dummyView subviews][0] removeFromSuperview];
    // ac = [[CPArrayController alloc] init];
    // [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow];
    // [self recheck_heights:dummyView];
    // }
    // return y_of_bottom_image + height_of_bottom_image;

    // console.log("number_of_rows_in_collection_view: " + number_of_rows_in_collection_view);
    // var retval = CGRectGetHeight([_cv bounds]) + cell_spacing_neglected_by_collection_view * number_of_rows_in_collection_view + [self headerLabelHeight];
    // console.log("Returning: " + retval);

    return CGRectGetHeight([_cv bounds]) + cell_spacing_neglected_by_collection_view * number_of_rows_in_collection_view + [self headerLabelHeight];



    // Let me explain the ridiculousness here.
    // First, read http://stackoverflow.com/questions/7504546 and understand that we need to build a dummy collection
    // view to solve the chicken&egg problem: we need to build a dummy coll view so that we can assign a row height,
    // which we need to do before building the coll view that goes in the table, because that view needs the row height
    // to render itself.
    // Now, that approach ALMOST worked, but it seems that when the coll. view underestimates its size (fogetting about the
    // space between cells, and if there is more than one row, then there is cutoff.  If there are a lot of rows, there is a
    // lot of cutoff.)
    // This problem is partly solved by reading the max y coordinate of the last image in the collection view, and using that
    // in the row height.  Unfortunately, you need to repeat that algorithm for each row in the collection view, because the
    // view rearranges itself and continues to spill out to be larger than the row.  You need to calculate the number of rows
    // in the collection view, and iterate the correction that number of times.
    // Now, it turns out each such iteration adds the SAME amount, so instead of iterating, I'll do it once, and then add
    // according to how much height was added.  Again, that amount is the difference between the cv's reported height and
    // the height found by looking at the bottom of the last image.
    // I can't think of another algorithm that solves this problem, so that's what I implemented

    // There seems to be a minor width issue.  See if the coll view's width is actually wider than it should be... Consider building it in a smaller view (?)
    //   (?) because that never worked for me before, I think it must be laid out inside the tableView's aView... which I don't think gives me leeway...
    //   unless I call setFrame on the collView.  Worth a shot.
}



// Now, tackle resizing in some basic way.
// Will need to call noteHeightOfRowsWithIndexesChanged when the scroll view resizes.
// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:self.scrollView.contentView];
// - (void)scrollViewContentBoundsDidChange:(NSNotification*)notification
// {
//     NSRange visibleRows = [self.tableView rowsInRect:self.scrollView.contentView.bounds];
//     [NSAnimationContext beginGrouping];
//     [[NSAnimationContext currentContext] setDuration:0];
//     [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
//     [NSAnimationContext endGrouping];
// }
// [NSAnimationContext beginGrouping];
// [[NSAnimationContext currentContext] setDuration:0];
// [tableView noteHeightOfRowsWithIndexesChanged:indexSet];
// [NSAnimationContext endGrouping];

- (void)recheck_heights:(CPView)aCvParentView
{
    var _cv = [aCvParentView subviews][0];
    console.log("---In recheck_heights!---");
    console.log("parent view height: " + CGRectGetHeight([aCvParentView frame]));
    console.log("cv height: " + CGRectGetHeight([_cv frame]));
    console.log("calculate from last image: " + CGRectGetMaxY([[_cv subviews][[[_cv subviews] count] - 1] frame]));
    console.log("---Out recheck_heights!---");
    return;
}

- (CPCollectionView)_makeCollectionViewForTableView:(CPTableView)aTableView arrayController:(CPArrayController)cvArrayController parentView:(CPView)aView  row:(int)aRow
{
    // var model = [self tableView:aTableView objectValueForTableColumn:nil row:aRow];
    var model = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
    // var cvArrayController = [[CPArrayController alloc] init],
        cv = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
    // [cv setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    console.log("model: ");
    console.log(model);  // SymbolCollection
    [cv setAutoresizesSubviews:NO];
    [cv setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [cv setMinItemSize:CGSizeMake(0,0)];  // Aha!  Now that the PhotoView has a frame, this works.  (the size isn't determined by this.)
    [cv setMaxItemSize:CGSizeMake(10000, 10000)];
    [cv setDelegate:self];
    [cv setSelectable:YES];
    // console.log("self photoViewInset: " + [self photoViewInset]);  // Good
    var itemPrototype = [[CPCollectionViewItem alloc] init],
        // photoView = [[PhotoView alloc] initWithFrame:CGRectMakeZero()];
        photoView = [[PhotoView alloc] initWithFrame:CGRectMakeZero() andInset:[self photoViewInset]];
    // [photoView setBounds:CGRectMake(0,0,[model maxRows],[model maxCols])];
    // [photoView setFrame:CGRectMake(0,0,[model maxCols]+20,[model maxRows]+20)];  // Good... now we just need the row height.  Hardcoded numbers though (more in PhotoView)
    [photoView setBounds:CGRectMake(0,0,[model maxCols],[model maxRows])];
    // [photoView setFrame:CGRectMake(0,0,[model maxCols],[model maxRows])];
    [photoView setFrame:CGRectMake(0,0,[model maxCols] + (2 * [photoView inset]), [model maxRows] + (2 * [photoView inset]))];
    [photoView setAutoresizesSubviews:NO];
    [photoView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [itemPrototype setView:photoView];
    [cv setItemPrototype:itemPrototype];
    [cv bind:@"content"
        toObject:cvArrayController
        withKeyPath:@"arrangedObjects"
        options:nil];
    // var bView = [[CPView alloc] initWithFrame:CGRectMake(1,1,1024,1)];
    //     neighborView = [[CPView alloc] init];  // Put this next to the coll view... try to get the coll view to take its natural amount of space.
    // [neighborView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMaxXMargin | CPViewMinXMargin | CPViewMinYMargin];
    // [bView addSubview:neighborView];
    [aView addSubview:cv];
    [cvArrayController setContent:[model glyphList]];
    console.log("_make returning cv for row: " + aRow + " of height: " + CGRectGetHeight([cv frame]));
    gCollectionView = cv;  //Debug
    return cv;
}
-(@action) printWindow:(id)aSender
{
    console.log(theWindow);
}
-(@action) printCv:(id)aSender
{
    console.log([self gCollectionView]);  //Debug
}
-(@action) printViewForFirstRow:(id)aSender
{
    var scrollView = [[theWindow contentView] subviews][0],
        clipView = [scrollView subviews][0],
        tableView = [clipView subviews][0],
        tableColumn = [tableView subviews][0],
        aView = [tableColumn subviews][1];  // not sure what [tableColumn subviews][0] is

    console.log(tableColumn);  //Debug
    [aView setNeedsDisplay:YES];  //?
    // [aView display];
}
- (void)tableViewColumnDidResize:(CPNotification)aNotification
{
    console.log("Resized.");
    var tableView = [aNotification object];
    [tableView noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,[tableView numberOfRows])]];
        // Maybe turn off animation for the above command
    // [tableView reloadData];  // Seems to perform about the same as reloadDataForRowIndexes
    var scrollView = [[tableView superview] superview],
        visibleRows = [tableView rowsInRect:[[scrollView contentView] bounds]];
    [tableView reloadDataForRowIndexes:visibleRows columnIndexes:0];
        // see http://stackoverflow.com/questions/12067018 for other approaches
}
// if (aTableView == [self theTableView])
// {
//     // coalesce all column resize notifications into one -- calls messagesViewDidResize: below
//     NSNotification* repostNotification = [NSNotification notificationWithName:BSMessageViewDidResizeNotification object:self];
//     [[NSNotificationQueue defaultQueue] enqueueNotification:repostNotification postingStyle:NSPostWhenIdle];
// }
// [aTableView noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:visibleRows]];
// console.log([[CPIndexSet alloc] initWithIndexesInRange:CPMakeRange(0,[aTableView numberOfRows])]);

// - (void)messagesViewDidResize:(CPNotification)aNotification
// {
//     var messagesView = self messagesView;
//     NSIndexSet indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,messagesView.numberOfRows)];
//     [messagesView noteHeightOfRowsWithIndexesChanged:indexes];
// }

// - (void)scrollViewContentBoundsDidChange:(CPNotification)aNotification
// {
//     console.log("notified!");
//     var scrollView = [self parentScrollView],
//         tableView = [self theTableView];
//     console.log([[scrollView contentView] bounds]);
//     var visibleRows = [tableView rowsInRect:[[scrollView contentView] bounds]];
//     console.log(visibleRows);
//     // [CPAnimationContext beginGrouping];
//     // [[CPAnimationContext currentContext] setDuration:0];
//     [tableView noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:visibleRows]];
//     // [CPAnimationContext endGrouping];
// }


// This function will help with selection... find a way to pass the event to the collection view
// - (void)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
// // Returns the height of a specified row
// {
//     return XXXX;
// }




@end
