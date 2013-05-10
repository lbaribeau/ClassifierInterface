from django.db import models
from ClassifierInterface.models.classifier import Classifier


class Project(models.Model):
    # Rodan project.  Stub.
    classifiers = models.ManyToManyField(Classifier, related_name="classifiers", blank=True)
    pass
