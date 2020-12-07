cmake_minimum_required(VERSION 3.16)

#----- Append EC specific module path
foreach(PATH $ENV{EC_CMAKE_MODULE_PATH})
   list(APPEND CMAKE_MODULE_PATH ${PATH})
endforeach()

include(ec_utils)   # Include EC specific cmake utils
ec_parse_manifest() # Parse MANIFEST file
ec_build_info()     # Generate build include file

#include(compiler_presets)
project(${NAME} VERSION ${VERSION} DESCRIPTION "${DESCRIPTION}")

set(CMAKE_INSTALL_PREFIX "" CACHE PATH "..." FORCE)

include(compiler_rules)

find_package(TCL ${TCL_REQ_VERSION} REQUIRED)
if(TCL_FOUND)
   add_library(TCL::TCL SHARED IMPORTED)
   set_target_properties(TCL::TCL PROPERTIES IMPORTED_LOCATION ${TCL_LIBRARY})
   target_include_directories(TCL::TCL INTERFACE ${TCL_INCLUDE_PATH})
   target_include_directories(TCL::TCL INTERFACE $ENV{TCL_SRC_DIR}/unix $ENV{TCL_SRC_DIR}/generic)
   target_compile_definitions(TCL::TCL INTERFACE HAVE_TCL TCL_THREADS)
endif()

find_package(eerUtils ${EER_REQ_VERSION} CONFIG REQUIRED)
find_package(RMN ${RMN_REQ_VERSION} COMPONENTS beta shared OPTIONAL)
find_package(VGRID ${VGRID_REQ_VERSION} COMPONENTS shared OPTIONAL)
find_package(GDAL ${GDAL_REQ_VERSION})
if(GDAL_FOUND)
   target_compile_definitions(GDAL::GDAL INTERFACE HAVE_GDAL)
endif()

if(${CMAKE_SYSTEM_PROCESSOR} EQUAL x86_64)
   add_compile_options(-fPIC -DSTDC_HEADERS)
endif()

add_compile_definitions(_${CMAKE_SYSTEM_NAME}_ TCL_THREADS _GNU_SOURCE _DEFAULT_SOURCE)

add_subdirectory(src src)

include(ec_bin_config)
