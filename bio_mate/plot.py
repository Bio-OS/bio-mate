from .BaseWidget import BaseWidget
from .defs import all_defs


def plot(type=""):
    all_defs[type]

    widget = BaseWidget(type=type, all_defs=all_defs)
    return widget
