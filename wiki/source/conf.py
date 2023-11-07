project = 'OrderLab Linux Development Guide'
copyright = '2023, OrderLab'
author = 'Ryan Huang, Yuzhuo Jing'
release = 'v1'

extensions = ['myst_parser']

html_context = {
    "display_github": True,
    "github_user": "OrderLab",
    "github_repo": "linux-dev-bootcamp",
    "github_version": "master",
    "conf_py_path": "/docs/source/",
}

source_suffix = ['.rst', '.md']

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

html_theme = "sphinx_rtd_theme"
