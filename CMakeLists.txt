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
add_compile_definitions(HAVE_TCL)
include_directories(${TCL_INCLUDE_PATH} ${TK_INCLUDE_PATH})
include_directories($ENV{TCL_SRC_DIR}/unix $ENV{TCL_SRC_DIR}/generic)
include_directories($ENV{TK_SRC_DIR}/unix $ENV{TK_SRC_DIR}/generic)

find_package(EER ${EER_REQ_VERSION} REQUIRED)
if (EER_FOUND) 
   add_compile_definitions(HAVE_EER)
   include_directories(${EER_INCLUDE_DIR})
endif()

#TODO --- COMPONENTS shared threaded
find_package(RMN ${RMN_REQ_VERSION} COMPONENTS beta shared OPTIONAL)
if (RMN_FOUND) 
   add_compile_definitions(HAVE_RMN)
   include_directories(${RMN_INCLUDE_DIR})
endif()

#find_package(VGRID ${VGRID_REQ_VERSION} COMPONENTS shared OPTIONAL)
#if(VGRID_FOUND)
#  add_compile_definitions(HAVE_VGRID)
#   include_directories(${VGRID_INCLUDE_DIR})
#endif()

find_package(GDAL ${GDAL_REQ_VERSION})
if(GDAL_FOUND)
   add_compile_definitions(HAVE_GDAL)
   include_directories(${GDAL_INCLUDE_DIR})
endif()

#if(DEFINED TCL_SRC_DIR)
#   add_compile_definitions(HAVE_TCL)
#   include_directories(${TCL_SRC_DIR}/unix ${TCL_SRC_DIR}/generic)
#endif()

if(${CMAKE_SYSTEM_PROCESSOR} EQUAL x86_64)
   add_compile_options(-fPIC -DSTDC_HEADERS)
endif()

add_compile_definitions(_${CMAKE_SYSTEM_NAME}_ TCL_THREADS _GNU_SOURCE _DEFAULT_SOURCE)

add_subdirectory(src src)
