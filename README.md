# GenPhysX Description

GenPhysX is the modern and easy-to-use surface fields generator at the CMC. It processes several geospatial databases, specifically averaging, counting, slope and aspect calculations and more. It supports hundreds of geospatial data file formats, including RPN standard files, and seamlessly manages geographical projections and datum. GenPhysX can generate surface fields at any scale for anywhere in the world. GenPhysX uses [SPI](https://gitlab.science.gc.ca/ECCC_CMOE_APPS/eerspi) at its core.

A set of databases are queried by GenPhysX to create model fields of quantities including:

- Mean orography
- Land/sea mask
- Fraction of various vegetation classes
- Soil types
- Subgrid-scale fields (e.g. roughness length, launching height, etc.)

GenPhysX is the next-generation geophysical field generator, and is intended to replace both gengeo and genesis. Updates to both the algorithms and the underlying geospatial databases are intended to enhance GenPhysX results in comparison with its predecessors, particularly for high resolution grids.


# [GenPhysX Documentation](https://wiki.cmc.ec.gc.ca/wiki/Genphysx#Documentation)

# [GenPhysX Databases](https://wiki.cmc.ec.gc.ca/wiki/GenPhysX/Databases)

# Building GenPhysX

You will have to define the environmenent variable SSM_DEV which defines the workspace and packaging location as bellow

```
$SSM_DEV/
   src
   package
   workspace
```

The ```makeit``` script at the root of the repository will allow you to build from source and produce an ssm package.

```makeit -reconf -build -ssm```

# GenPhysX test suite

# Automatic Testing using GitLab-CI

An automatic system of tests has been developed.  For each push in the
`master` branch the system tests are launched to guarantee that the
all the tests pass for the `master` branch.