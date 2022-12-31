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
import re

# -- Project information -----------------------------------------------------

project = "acsylla"
copyright = "2020, Pau Freixes"
author = "Pau Freixes"

# The full version, including alpha/beta/rc tags
with open(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../acsylla/version.py")) as fp:
    try:
        version = re.findall(r"^__version__ = \"([^']+)\"\r?$", fp.read())[0]
        release = version
    except IndexError:
        raise RuntimeError("Unable to determine version.")

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx.ext.duration",
    "sphinx.ext.doctest",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.todo",
    "sphinx.ext.intersphinx",
    "sphinx.ext.mathjax",
    "sphinx.ext.viewcode",
    "sphinx.ext.graphviz",
    # "sphinx.ext.napoleon",
]
autosummary_generate = True
autodoc_member_order = "bysource"
# napoleon_use_admonition_for_examples = True
# napoleon_use_admonition_for_notes = True
# napoleon_use_admonition_for_references = True
# napoleon_use_keyword = True
# napoleon_preprocess_types = True
# napoleon_use_ivar = True
# napoleon_use_param = True
# napoleon_custom_sections = True
# napoleon_attr_annotations = True

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------

nitpicky = True
nitpick_ignore = [
    ("py:class", "Optional[~ KT]"),
    ("py:class", "KT"),
    ("py:class", "Optional[~ VT]"),
    ("py:class", "VT"),
]

# If true, '()' will be appended to :func: etc. cross-reference text.
add_function_parentheses = True
pygments_style = "sphinx"
highlight_language = "python3"
# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "alabaster"
# chtml_logo = "../logo/cassandra-scylladb.svg"

html_theme_options = {
    "description": "A high performance Python Asyncio client library for Cassandra and ScyllaDB",
    "github_user": "acsylla",
    "github_repo": "acsylla",
    "github_button": False,
    "github_banner": True,
    "github_type": "Stars",
    "github_count": True,
    "note_bg": "#E5ECD1",
    "note_border": "#BFCF8C",
    "body_text": "#482C0A",
    "sidebar_text": "#49443E",
    "sidebar_header": "#4B4032",
    # 'sidebar_width': '20%',
    # 'body_min_width': '80%',
    # 'page_width': '90%',
    # 'body_max_width': '1200px',
    "code_font_size": "0.8em",
    "show_related": True,
    "show_relbars": True,
}
# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
# html_static_path = ["_static"]
