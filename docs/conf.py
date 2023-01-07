# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys

sys.path.insert(0, os.path.abspath(".."))
from pathlib import Path


# -- Project information -----------------------------------------------------

project = "ECODATA-Animate"
copyright = "2023, Justine Missik"
author = "Justine Missik"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",  # Create neat summary tables for modules/classes/methods etc
    "sphinx.ext.napoleon",
    "sphinx.ext.todo",
    "sphinxcontrib.matlab",
    "myst_parser",
]

pygments_style='default'

nbsphinx_execute = "never"

autosummary_generate = True  # Turn on sphinx.ext.autosummary
add_module_names = False

source_suffix = [".rst", ".md", ".ipynb"]

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

todo_include_todos = True

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
# html_theme = "sphinx_book_theme"
# html_theme = "press"
# html_theme = "sphinx_material"
# html_theme = 'alabaster'
# html_theme = 'pydata_sphinx_theme'
html_theme = "furo"
# html_theme = "sphinxawesome_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
# html_static_path = ['_static']

# MATLAB setup
matlab_src_dir = Path(__file__).parent.parent
# primary_domain = 'mat'

# this_dir = os.path.dirname(os.path.abspath(__file__))
# matlab_src_dir = os.path.abspath(os.path.join(this_dir, '..'))
# primary_domain = 'mat'

html_theme_options = {
    "external_links": [("Github", "https://github.com/jemissik/movebank_vis")]
}
