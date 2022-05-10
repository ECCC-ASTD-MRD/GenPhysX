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

# Getting the source code
```shell
git clone --recursive git@gitlab.science.gc.ca:ECCC_CMOE_APPS/GenPhysX
```
# Building GenPhysX
You will need cmake with a version at least 3.21
```shell
. ssmuse-sh -x /fs/ssm/main/opt/cmake-3.21.1
```
# Building GenPhysX

## Optional dependencies
* codetools and compilers
```shell
. r.load.dot rpn/code-tools/ENV/cdt-1.5.3-intel-19.0.3.199
```

* [librmn](https://gitlab.science.gc.ca/RPN-SI/librmn)
```shell
. r.load.dot rpn/libs/19.7.0
```

* [vgrid](https://gitlab.science.gc.ca/RPN-SI/vgrid)
```shell
. r.load.dot rpn/vgrid/6.5.0
```

* External dependencies ([GDAL](https://gdal.org/). Within the ECCC/SCIENCE network, a package containing all the dependencies can be loaded
```shell
export CMD_EXT_PATH=/fs/ssm/eccc/cmd/cmds/ext/20210211; . ssmuse-sh -x $CMD_EXT_PATH
```

## Environment setup (At CMC)

Source the right file depending on the architecture you need from the env directory. This will load the specified compiler and define the ECCI_DATA_DIR variable for the test datasets

- Example for PPP3 and skylake specific architecture:
```shell
. ci-env/latest/ubuntu-18.04-skylake-64/intel-19.0.3.199.sh
```

- Example for XC50 on intel-19.0.5
```shell
. ci-env/latest/sles-15-skylake-64/intel-19.0.5.281.sh
```

- Example for CMC network and gnu 7.5:
```shell
. ci-env/latest/ubuntu-18.04-amd-64/gnu-7.5.0.sh
```

## Build, install and package
```shell
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$SSM_DEV/workspace -DeerUtils_ROOT=$SSM_DEV/workspace/eerUtils_4.1.1-intel-19.0.3.199_ubuntu-18.04-skylake-64/ ../
make -j 4
make test
make install
make package
```