#!/bin/bash

CI_PROJECT_DIR=$1
CI_BUILD_REF=$2

#----- Got to project 
cd ${CI_PROJECT_DIR}

#----- Initialize environment
. ./VERSION

export SPI_LIB=${SSM_DEV}/workspace/libSPI_${SPI_VERSION}${SSM_COMP}_${ORDENV_PLAT}
export SPI_PATH=${SSM_DEV}/workspace/SPI_${SPI_VERSION}_all
export CI_DATA_IN=${CI_DATA}/GenPhysX/in
export CI_DATA_OUT=${CI_DATA}/GenPhysX/out/${CI_BUILD_REF}

#----- Launch tests
mkdir -p $CI_DATA_OUT
${CI_PROJECT_DIR}/bin/GenPhysX -target GDPS_5.1 -gridfile ${CI_DATA_IN}/GDPS_5.1.fst -result ${CI_DATA_OUT}/GDPS_5.1 > ${CI_PROJECT_DIR}/CI.log
echo "Status: $?" >> ${CI_PROJECT_DIR}/CI.log
