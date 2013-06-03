# Interactive classifier job

  # User clicks 'Work On Job' for interactive classifier.  This sends a request for PageGlyphs to the server

# Maybe this is a GET to an API point that provides classification.
 # server code:
    binary_image = load_image("…")  #Get the image from the output of the last job (binarization)
    ccs = binary_image.cc_analysis()
    # Run the glyphs through the classifier - let it make guesses
    # The user should choose a classifier in the settings for the job by name.
    gamera_classifier = kNNNonInteractive()
    django_classifier = Classifier.objects.filter(name=job_settings.name)
    # Validate: make sure we found our classifier
    gamera_classifier.from_xml_filename(django_classifier.classifier_path))
    grouping_function = classify.ShapedGroupingFunction(job_settings.GroupingDistanceThreshold)  # something like 16
    gamera_classifier.group_and_update_list_automatic(ccs, grouping_function, max_parts_per_group = job_settings.max_parts_per_group)  # something like 4
    # Job settings we'll need:
    #   Bounding box size
    #   Maximum number of parts per group
    #   Maximum solveable subgraph size (maybe we can hide this from the user)
    # Just dump it to xml, and then use my code that converts it to JSON
    # There are gamers functions to do it, but they're a little hidden… so do it manually
    buf = StringIO.StringIO()
    buf.write("<glyphs>")
    for glyph in ccs:
        buf.write(glyph.to_xml)
    buf.write("</glyphs>")
    classifier.init(buf)  # will have to write this into my server side model.
      # This isn't a classifier!  I should rename the model to "GameraXML"
      

convert_xml_to_json(buf)  # I (basically) wrote this already in classifier.py: def glyphs

# I think the Classifier model needs to be named more generically… it's more like GameraXML  (generic to a Classifier and to PageGlyphs)

# My plan: integrate my stuff into rodan.  Augment the Classifier model to handle what I need from it above.  Ask Deep to write this job for me.
