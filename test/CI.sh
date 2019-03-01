#!/bin/bash

CI_PROJECT_DIR=$1
CI_BUILD_REF=$2

#----- Got to project 
cd ${CI_PROJECT_DIR}

#----- Initialize environment
. ./VERSION

export SPI_LIB=${SSM_DEV}/workspace/libSPI_${SPI_VERSION}${SSM_COMP}_${ORDENV_PLAT}
export SPI_PATH=${SSM_DEV}/workspace/SPI_${SPI_VERSION}_all
export CI_GENPYSX_IN=/home/nil000/links/eccc-ppp1/storage/SPI/DataIn
export CI_GENPYSX_OUT=`mktemp -d`

#----- Launch tests
mkdir -p $CI_GENPYSX_OUT
echo "Path  : ${CI_GENPYSX_OUT}" > ${CI_PROJECT_DIR}/CI
echo "Log   : GenPhysX-${CI_BUILD_REF}.log" >> ${CI_PROJECT_DIR}/CI
${CI_PROJECT_DIR}/bin/GenPhysX -target GDPS_5.1 -gridfile ${CI_GENPYSX_IN}/GDPS_5.1.fst -result ${CI_GENPYSX_OUT}/GDPS_5.1 > GenPhysX-${CI_BUILD_REF}.log
echo "Status: $?" >> ${CI_PROJECT_DIR}/CI
