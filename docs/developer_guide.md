# Developer guide

## Contributing
Check out this [simple guide for using git](https://rogerdudler.github.io/git-guide/).

1. Create a new branch for your contributions.
2. Commit your changes in this branch.
3. [Open a pull request](https://github.com/jemissik/movebank_vis/pulls) to merge changes from your branch into the
repository's ``develop`` branch.


## Documentation

Documentation for this project is created using Sphinx and is hosted at Read the Docs (https://ecodata-animate.readthedocs.io/). The source files
for these pages are located in the [docs folder](https://github.com/jemissik/movebank_vis/tree/develop/docs) of the repository. To edit the documentation, edit the markdown files in this folder (or sub-folders). Note that the ``docs/index.md`` file specifies the contents for the docs site. If a sub-folder has a ``index.md`` file, that file specifies the contents for that section of the docs site (e.g. ``docs/user_guide/index.md``). If files are added or removed, the corresponsing index files will also need to be updated.

### Building the docs
After editing the pages, you can look at a build of the pages to see how things will actually look in the docs website. There are two options for this:
- Option 1: [Open a pull request](https://github.com/jemissik/movebank_vis/pulls), and Read the Docs will build a preview of the docs pages. A link to the build can be found near the bottom of the page of the PR, in the merge checks section (once the build is finished, click on "Details" for the docs/readthedocs.org:ecodata-animate item.
You may have to click "Show details" next to where it says "All checks have passed"). You can push additional commits to the open PR if you want to change anything after seeing the preview build.
- Option 2: Build the docs locally. You will need to have python and the docs requirements installed.

    - To install the doc requirements: ``pip install sphinx furo sphinxcontrib-matlabdomain myst-parser`` or install
    using the conda or pip requirements file (located in the ``docs`` directory)
    - Build the docs: ``sphinx-build -b html docs docs/_build``
    - To view the build, open the ``index.html`` in the docs/_build directory that was created.

### Versions of the docs
- Read the Docs builds multiple versions of the documentation (for different branches of the repository). In the bottom corner of the docs pages, there is a box indicating which version you are viewing. You can click on that box to pick a different version.



## Setup instructions for the MATLAB code

### Adding datasets
- Most of the datasets are too large to be stored in the repository
- Datasets used in the example scripts can be downloaded [here](https://drive.google.com/drive/folders/1pyK4E-z8XUjRlYKYFX5L198YOlvOoUHA?usp=sharing)
- Copy any datasets you want to use to ``data/user_datasets``
### Adding topo data for the m_map package
- [Download the topo data](https://drive.google.com/drive/folders/1RmhHbSsm15i5xQVMWLaerv39fHja2fgr?usp=sharing)
- Copy the contents of this folder to ``m_map/data``
### Specifying Movebank login credentials:
- Save ``movebank_credentials_template.txt`` as ``movebank_credentials.txt`` and update it with your username and password.
- ``movebank_credentials.txt`` is in the .gitignore so it won't be tracked.
