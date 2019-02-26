#!/bin/bash
. ./VERSION

HOST=eccc-ppp1
CI_TEST_PATH=/home/nil000/links/eccc-ppp1/storage/CI/

CI_PATH=${CI_TEST_PATH}/GenPhysX
mkdir -p ${CI_PATH}/out/${CI_BUILD_REF}

cat > ${CI_PATH}/out/CI_GenPhysX.sh <<ENDOFTEST
export SPI_LIB=${SSM_DEV}/workspace/libSPI_${SPI_VERSION}-\${COMP_ARCH}_\${ORDENV_PLAT}
export SPI_PATH=${SSM_DEV}/workspace/SPI_${SPI_VERSION}_all

#----- GDPS_5.1
${CI_PROJECT_DIR}/bin/GenPhysX -target GDPS_5.1 -gridfile ${CI_PATH}/in/GDPS_5.1.fst -result ${CI_PATH}/out/${CI_BUILD_REF}/GDPS_5.1_test 
ENDOFTEST

ord_soumet ${CI_PATH}/out/CI_GenPhysX.sh -mach $HOST -queue DEV -cpus 4 -w 180
