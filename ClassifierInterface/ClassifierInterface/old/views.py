from rest_framework import generics
from rest_framework import permissions
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.reverse import reverse
from django.views.decorators.csrf import ensure_csrf_cookie
from django.shortcuts import render

from ClassifierInterface.models import Classifier
from ClassifierInterface.serializers import ClassifierSerializer

from lxml import etree
import re
import png
import StringIO
import base64

UPLOADS = "/Users/lbaribeau/ClassifierInterface/uploads/"


@api_view(('GET',))
def api_root(request, format=None):
    return Response({
        'classifiers': reverse('classifier-list', request=request, format=format)
    })
# I don't actually want to use a generic view here.  I'll just try it out though.  But
# really I will want to send pngs when someone asks for the classifier.
#class ClassifierList(generics.ListCreateAPIView):
#    model = Classifier
#    permission_classes = (permissions.AllowAny,) #TODO: Delete this
#    serializer_class = ClassifierSerializer
#
#class ClassifierDetail(generics.RetrieveUpdateDestroyAPIView):
#    model = Classifier
#    permission_classes = (permissions.AllowAny,) #TODO: Delete this
#    serializer_class = ClassifierSerializer
#
#@ensure_csrf_cookie
#def home(request):
#    return render(request, 'index.html', {})


def interface(request):
    return render(request, 'index.html', {})


@api_view(['GET'])
def home(request):
    encoded_glyphs = get_glyph_pngs(2)
    # Serialze the list into JSON:
    response_list = [{"glyph_png": encoded_glyphs[i]} for i in range(0, len(encoded_glyphs))]
    return Response(response_list)


def get_glyph_pngs(id):
    # Make a png from the xml file.
    # Server side path to xml file:
    # This won't be in home... it'll be at /classifier/[UUID]$
    encoded_glyphs = []
    for event, element in etree.iterparse(UPLOADS + "projects/1/classifiers/" + str(id) + "/" + str(id) + ".xml"):
        if (element.tag == "data"):  # Maybe a better way in lxml to get to the data element
            ncols = int(element.getparent().get("ncols"))
            nrows = int(element.getparent().get("nrows"))
            # Make an iterable that yields each row in boxed row flat pixel format.*
            # *http://pypng.googlecode.com/svn/trunk/code/png.py
            # Plan: make a list of length nrows * ncols * 3 then make sublists of length ncols * 3.
            # The *3 is for RGB: (0,0,0) is black and (255,255,255) is white
            pixels = []
            white_or_black = True
            for n in re.findall("\d+", element.text):
                pixels.extend([255 * white_or_black] * int(n))
                white_or_black = not(white_or_black)
            png_writer = png.Writer(width=ncols, height=nrows, greyscale=True)
            pixels_2D = []
            for i in xrange(nrows):
                pixels_2D.append(pixels[i*ncols: (i+1)*ncols])  # Index one row of pixels
            # StringIO.StringIO lets you write to strings as files: it gives you a file descriptor.
            # (pypng expects a file descriptor)
            buf = StringIO.StringIO()
            #image = png.from_array(pixels_2D,mode='L')
            #image.save(buf) # Hopefully this doesn't write to a file
            png_writer.write(buf, pixels_2D)
            my_png = buf.getvalue()
            encoded_png = base64.b64encode(my_png)  # not sure why
            encoded_glyphs.append(encoded_png)
    return encoded_glyphs

# OPEN Classifier
# Server side:  Receive request containing classifier name
# Database get classifier by name
# Use that object's get_glyphs method and return as JSON ***
# - May be able to have a serializer do it.





