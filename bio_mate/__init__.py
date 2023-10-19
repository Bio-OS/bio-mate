from ._version import __version__


def _jupyter_labextension_paths():
    return [{
        "src": "labextension",
        "dest": "bio-mate"
    }]


print("init_bio_mate")

from .plot import plot
