from ClassifierInterface.models import Classifier
from rest_framework import serializers


class ClassifierSerializer(serializers.HyperlinkedModelSerializer):
    glyphs = serializers.Field(source="glyphs")

    class Meta:
        model = Classifier
        fields = ("url", "name", "glyphs")

#class PngSerializer(serializers.HyperlinkedM
# Hmm... going simpler instead.  I don't really need a model nor a serializer right now.
