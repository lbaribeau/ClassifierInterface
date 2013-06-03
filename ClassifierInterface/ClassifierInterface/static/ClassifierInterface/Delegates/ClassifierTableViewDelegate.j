@import "../Views/PhotoView.j"
@import "../Views/ViewWithObjectValue.j"
@import "../Models/SymbolCollection.j"
@import "../Models/Classifier.j"

@implementation ClassifierTableViewDelegate : CPObject
{
    @outlet CPArrayController symbolCollectionArrayController;
    CPArray cvArrayControllers @accessors;
    int headerLabelHeight @accessors;
    int photoViewInset @accessors;
    @outlet CPTableView theTableView;
}
- (void)init
{
    self = [super init];
    [self setHeaderLabelHeight:20];
    [self setPhotoViewInset:10];
    // [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentBoundsDidChange:) name:CPViewBoundsDidChangeNotification object:self.scrollView.contentView];
    [self setCvArrayControllers:[[CPArray alloc] init]];
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
            [symbolCollection addGlyph:glyphs[i]];
        }
        [symbolCollection setMaxRows:maxRows];
        [symbolCollection setMaxCols:maxCols];
        [symbolCollectionArray addObject:symbolCollection];
    }
    [symbolCollectionArrayController setContent:symbolCollectionArray];
    var nSymbols = [[symbolCollectionArrayController contentArray] count];
    [cvArrayControllers initWithCapacity:nSymbols];
    for (var j = 0; j < nSymbols; ++j)
    {
        cvArrayControllers[j] = [[CPArrayController alloc] init];
        [cvArrayControllers[j] setContent:[symbolCollectionArray[j] glyphList]];
        // [cvArrayControllers[j] setAvoidsEmptySelection:NO];  // Still can't deselect... (this is more for if an item is removed)
        [cvArrayControllers[j] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
    }
    // console.log("selection indexes initialized:");
    // console.log([cvArrayControllers[0] selectionIndexes]);
}
- (void)close
{
    [symbolCollectionArrayController setContent:[]];  // Also need to kill all of the subArrays.
      // Also need to unset all of the symbolCollections... the labels are bound to that model, and not through the array controller
      // Maybe the label ought to be bound through the array controller... like with objectValue (via the table's binding)
        // Use a dict of arrays keyed by symbol name.
    // var enumerator = [cvArrayControllerDict objectEnumerator],
    //     cvArrayController;
    // while (cvArrayController = [enumerator nextObject])
    // {
    //     [cvArrayController setContent:[]];
    // }
    // [cvArrayControllerDict removeAllObjects];
    [theTableView reloadData];
    // Ok.  I didn't even need the cvArrayControllerDict for this.  Wow.
    // So my first approach was sort of a 'binding' style approach in which I was hoping that the table view would
    // empty when I killed the content of the array controller.  However, I'm not using binding, I'm using a coded
    // approach, because of all of the hooplah with the collection view and the row height.  So the best binding
    // could do would be to empty the coll views and labels, but the tableView would still sort of be there (and the
    // scroll bar,) so it's much better to just tell the tableView what to do explicitly (reloadData... after erasing
    // the data).  Side note: the SymbolOutline uses the former approach (binding.)
}





// ------------------------------------- DELEGATE METHODS ----------------------------------------------





- (CPView)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Return a view for the TableView to use a cell of the table.
{
    // console.log('---viewForTableColumn---');
    // if (cachedViews[aRow])
    // {
    //     return cachedViews[aRow];
    // }
    // else
    // {
    //     cachedViews[aRow] = [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
    //     return cachedViews[aRow];  // Nope... doesn't display!
    // }
    // console.log([cvArrayControllers[0] selectionIndexes]);
    return [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
}
- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Set up the view to display.  (Delegate method.)
// (Note: I do things in this function so that I have access to objectValue... which I don't in viewForTableColumn.)
{
    console.log("---willDisplayView---");
    var symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:aTableColumn row:aRow],
        symbolName = [symbolCollection symbolName],  // If I use binding, I don't need this variable
        label = [[CPTextField alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth([aView bounds]), [self headerLabelHeight])];
    [label setStringValue:symbolName];
    [label setFont:[CPFont boldSystemFontOfSize:16]];
    [label setAutoresizesSubviews:NO];
    [label setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin];
    [aView addSubview:label];

    var parentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [aView setAutoresizesSubviews:NO];
        //It's driving me bonkers: why doesn't the label get pinned to the top of aView upon resize???  (Not using Autosize!)
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [parentView setAutoresizesSubviews:NO];
    [parentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [aView addSubview:parentView];
    [parentView setFrame:CGRectMake(0, [self headerLabelHeight], CGRectGetWidth([aView bounds]), CGRectGetHeight([aView bounds]) - [self headerLabelHeight])];
    var cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayControllers[aRow] parentView:parentView row:aRow];
    // [cv bind:@"selectionIndexes" toObject:cvArrayControllers[aRow] withKeyPath:@"selectionIndexes" options:nil];
    [cv setSelectionIndexes:[cvArrayControllers[aRow] selectionIndexes]];  // This should allow you to scroll down and back and have the selection persist
        // Now... when did cvArrayControllers[aRow] selectionIndexes get erased!
        // Maybe the binding isn't working... or maybe the array controller
    if (aRow === 0)
    {
        console.log("Set cv0 selection indexes to:__ (this shouldn't deselect when scrolling!)");
        console.log([cvArrayControllers[aRow] selectionIndexes]);
    }
    [cvArrayControllers[aRow] bind:@"selectionIndexes" toObject:cv withKeyPath:@"selectionIndexes" options:nil];  // should overwrite the binding to the last cv

    // [cv addObserver:self forKeyPath:@"selectionIndexes" options:CPKeyValueObservingOptionInitial context:nil];
    [cv addObserver:self forKeyPath:@"selectionIndexes" options:nil context:aRow];
        // This is happening too many times.
        // I guess the same cv is persisting??  That's not even possible, _make allocs a new one.
        // Try checking for an observer.
        // Maybe I should use a different object just to keep things separate... Nah I need access to the arrayControllers.
        // Actually... maybe not!  It's just the first click after it comes back that calls tons.
        // The real problem is the selection changing on scroll.
        // I scroll down and scroll back and I get one more call to notify, so the problem is because EACH collection view
        // has an observer on it.  The clicking is fine.
        // Problem.
        //  - EACH collection view has an observer on it AND the selection changes from scrolling.
        //  Just change the latter and we're good(?)
        //  It would be good to free the previous collection view... we shouldn't collect collection views by scrolling!
        // It's a relief that the array controller array is working, at least I think it is.
        // I think that the selection changes because of the binding.  Although, that doesn't make sense looking at the code.
        // The amount of additional calls to observeValueForKeyPath is proportional to the amount that you scroll.
        // If you scroll down and back and down and back... you then get a ton of 'observeValueForKeyPaths' whenever a selection changes.
        // Perhaps I need to clean up the collection views a little better... (ensure that they get deleted... or at least unbound to the
        // array controller.)
        // What if I bind it in the other direction: the array controller to the cv.  There would be a bit of a handshake where the indeces of
        // the new cv are set by the array controller and then the array controller rebinds to the new CV.
        // Another question... if it gets called 3 times when I click... why?
        //  Twice on a new window.  (why twice?)
        //  Once if I click and the selection doesn't change.
        //  Twice if I change selections in the same collectionView
        //  Thrice if I scroll down and click.
        //    - Deselection of first one, plus two for the change of selection of the clicked one (good)
        // Twice on a new window... the first Change has both new and old the same (one selected) but the second change is as expected (old=none selected)
        // Anyway... that seems to work.  It's just the memory to check now.  I think it works!  I think it forgets one or two but not often :)

}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(CPCollectionView)aCollectionView change:(CPDictionary)aChange context:(id)aContext
// KVO (Key Value Observing) method.  This is how I trigger code when the collection view changes selection.
// References:
// 1. NSKeyValueObserving Protocol Reference
// 2. http://www.cocoabuilder.com/archive/cocoa/220039-nscollectionview-getting-notified-of-selection-change.html
// addObserver and implement the right method on the observer (use a new class: collectionViewObserver)
// aChange is a neato dictionary.
// aContext is the row that got clicked.
// Why does this get called when I scroll around???  I suppose it's because it changed on the collection view
// and not the array controller?  (because a new cView was made?  Or the old cView got dropped?)
// I get a new collection view every time it goes out and back...
// I NEED a way to list the observers on the collection view.
{
    console.log("observeValueForKeyPath");
    console.log(aChange);
    var theClickedRow = aContext;
    // console.log([aChange objectForKey:@"CPKeyValueChangeNewKey"]);
    // console.log([aChange objectForKey:@"CPKeyValueChangeOldKey"]);
    // console.log([aChange objectForKey:@"CPKeyValueChangeKindKey"]);
    // console.log([aChange allKeys]);
    // console.log([aChange allValues]);
    // Check if the new indexSet is empty.
    var newIndexSet = [aChange valueForKey:@"CPKeyValueChangeNewKey"];
    // console.log([aChange valueForKey:@"CPKeyValueChangeNewKey"]);
    // console.log("Old: " + [aChange valueForKey:@"CPKeyValueChangeOldKey"]);  //null
    // console.log("Changed: " + [aChange valueForKey:@"CPKeyValueChangeKindKey"]);  //null
    // console.log(newIndexSet);
    // console.log([newIndexSet firstIndex]);
    // if ([newIndexSet firstIndex] == -1)  // is False when firstIndex is 0 as well as when
    //     console.log("True!");
    // else
    //     console.log("False!");
    // if (newIndexSet == [CPIndexSet indexSet])
    //     console.log("Empty!");
    // else
    //     console.log("Unempty!");
    // console.log([aCollectionView observationInfo]);

    if (([newIndexSet firstIndex] > -1) && ! ([[CPApp currentEvent] modifierFlags] & (CPShiftKeyMask | CPCommandKeyMask)))  //http://stackoverflow.com/questions/9268045
    {
        // console.log(aCollectionView);
        // console.log([aCollectionView observationInfo]);
        // console.log("Nullifying.");

        // Nullify the selection on all other rows.
        var i = 0,
            nArrayControllers = [cvArrayControllers count];
        for (; i < nArrayControllers; ++i)
        {
            if (i !== theClickedRow)
            {
                [cvArrayControllers[i] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
            }
        }
    }
    // Ok, so what do?
    // if not shift*
    //   nullify selections of all other array controllers
    //   if no change and it's a single selection
    //     deselect
    //   else
    //     default (don't implement) (let the change go through)
    // if shift
    //   default

    // *Problem: infinite loop.  I when I change the index of the other views, it calls this notification.
    // Solution: check at the beginning of the function and only act if a selection was ADDED and do not act
    // if the newIndexSet is -1.  That breaks the loop.
    // Discussion:
    // I don't have access to all the collection views.
    // Look at what change is taking place:  if it was deselection, (like if the new selection is nil,) then
    // don't do the nullify.  This is necessary to break the infinite loop.  If it was a single deselection,
    // then ctrl is pressed.  What about single click deselection without ctrl... in that case, don't nullify (checking
    // aChange for empty still works.)  Basically, if the change was to nullify the selection, then don't proceed.

    // Only problem remaining is if you shift click without a current selection.  I think that's why the array
    // controllers are initialized with a selection.  When I shift click a collectionView with no selection, it
    // tries to select the range {-1, <clickedNode>}.  Maybe I should look at the Range that I'm setting up (try 0,0).
    // Ok, (0,0) works the same.  I just need to convince a collectionView to make a selection when it's shift clicked
    // from empty.  I guess it tosses CPInvalidArgumentException.

    // It would be REALLY nice if I had that global array that was a composition of all the collection view arrays.
    // That way, on a shift click, I could ask that array controller for an index, and then make a range from there
    // to the new click.
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
    var ac = [[CPArrayController alloc] init],
        dummyView = [[CPView alloc] initWithFrame:CGRectMake(1,1,CGRectGetWidth([aTableView bounds]),1)],
        _cv = [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow],
        symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
        glyphWidth = [symbolCollection maxCols] + (2 * [self photoViewInset]),
        glyphCount = [[symbolCollection glyphList] count],
        tableWidth = CGRectGetWidth([aTableView bounds]),
        number_of_rows_in_collection_view = Math.ceil((glyphWidth * glyphCount) / tableWidth),
        bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame],
        bottom_of_last_image = CGRectGetMaxY(bottom_image_frame),
        cell_spacing_neglected_by_collection_view = bottom_of_last_image - CGRectGetHeight([_cv bounds]);
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
    var model = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
        cv = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
    [cv setAutoresizesSubviews:NO];
    [cv setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [cv setMinItemSize:CGSizeMake(0,0)];  // Aha!  Now that the PhotoView has a frame, this works.  (the size isn't determined by this.)
    [cv setMaxItemSize:CGSizeMake(10000, 10000)];
    [cv setDelegate:self];
    [cv setSelectable:YES];
    [cv setAllowsMultipleSelection:YES];
    var itemPrototype = [[CPCollectionViewItem alloc] init],
        photoView = [[PhotoView alloc] initWithFrame:CGRectMakeZero() andInset:[self photoViewInset]];
    [photoView setBounds:CGRectMake(0,0,[model maxCols],[model maxRows])];
    [photoView setFrame:CGRectMake(0,0,[model maxCols] + (2 * [photoView inset]), [model maxRows] + (2 * [photoView inset]))];
    [photoView setAutoresizesSubviews:NO];
    [photoView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [itemPrototype setView:photoView];
    [cv setItemPrototype:itemPrototype];
    [cv bind:@"content"
        toObject:cvArrayController
        withKeyPath:@"arrangedObjects"
        options:nil];
    [aView addSubview:cv];
    // [cvArrayController setContent:[model glyphList]];
        // I think this erases my selection indexes... but I do it to kick the collection view to display...
        // I think that I'll start a pattern of BINDING LATER (after content is set,) and just kicking the view with setContent
        // The binding handles CHANGES, but doesn't need to handle the initialization, because it constrains the order of operation too much.
        // Careful about changing this though... it'll affect the row height calculation.
        // That will be fixed by using the same array controller from the row height (in fact, just delete that argument.)
    [cv setContent:[model glyphList]];  // Hopefully the binding still works, I'll have to test that later.
        // Recall: I had to interrupt the pattern of ONLY BINDING and NOT CALLING SetContent because that required that
        // I setContent of the array controller AFTER the view has been bound.  However, the view has to be rebuilt whenever you
        // scroll past it, so I cannot setContent of the array controller that often!  It erases the selection!  That, in short,
        // is why I need to both BIND and setContent.

    // console.log("_make returning cv for row: " + aRow + " of height: " + CGRectGetHeight([cv frame]));
    return cv;
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
// This function will help with selection... find a way to pass the event to the collection view
- (void)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
// Returns the height of a specified row
{
    console.log("ShouldSelectRow");
    if ([[cvArrayControllers[aRow] selectionIndexes] count] === [[cvArrayControllers[aRow] contentArray] count])
    {
        // all are selected
        [cvArrayControllers[aRow] setSelectedObjects:[]];
    }
    else
    {
        [cvArrayControllers[aRow] setSelectedObjects:[cvArrayControllers[aRow] contentArray]];
    }
    return NO;
}
// Hmmm deselect of a single element?  Not needed as much as the collection views talking to eachother.
// Persistent selection is just fine (only deselect when a new thing is selected...)
// but I want a more global selection object.  When a second collection view is clicked, then I need to deselect from the first
// collection view, AND when a second is clicked with shift clicked, I need to retain the selection.
// I need a really global array controller... that is just all of the cvArrayControllers in series... so the collectionViews
// are bound to the little array controllers... I don't think I can bind them to a subArray of the global one... so all that code
// will stay... so I need to write a wrapper/handler that responds to every change in selection of any array controller...
// maybe I can bind...
// The handler should subscribe to ALL changes in selection (the controller must have a selectionDidChange,)... then it can also
// have full control of what happens: it can deselect all selections in the other controllers if shift isn't pressed, etc.  Then
// the text box can take its cues from the global controller.  Call it SelectionController.  It can have the TableViewDelegate and
// the SymbolTableDelegate.  It won't need the table view, because the collectionViews are bound to the array controllers, (so they
// won't need to be kicked.)  It only needs the symbolTable's array controller because it can calculate everything it needs from the
// selection<Symbol>.name.
// Well... I'm not sure that the array controller has such a notification, but the collection views do!  I'll just set them all
// to have the same delegate!
@end
