cmake_minimum_required(VERSION 3.12)

#----- Append EC specific module path
list(APPEND CMAKE_MODULE_PATH $ENV{EC_CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake_rpn/modules)

include(ec_init)               # Include EC specific cmake utils
include(ec_shared_lib)         # Shared library related functions
include(ec_build_tcl_pkgindex) # Tcl package generation
ec_git_version()               # Get version from git state
ec_parse_manifest()            # Parse MANIFEST file

project(${NAME} DESCRIPTION "${DESCRIPTION}")
set(PROJECT_VERSION ${VERSION}${STATE})

ec_build_info()            # Generate build include file

enable_language(C)
enable_language(Fortran)

include(ec_compiler_presets)

#----- Look for non system default gdal
execute_process(
      COMMAND gdal-config --prefix
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      RESULT_VARIABLE GDAL_RESULT
      OUTPUT_VARIABLE GDAL_ROOT
      ERROR_VARIABLE GDAL_ERROR
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE
   )

#----- Look for built dependencies
ec_install_prefix(eerUtils ${EER_REQ_VERSION} eer_prefix)
set(eerUtils_ROOT ${CMAKE_INSTALL_PREFIX}/${eer_prefix})

ec_install_prefix(libSPI ${SPI_REQ_VERSION} spi_prefix)
set(SPI_ROOT ${CMAKE_INSTALL_PREFIX}/${spi_prefix})
set(TCL_ROOT ${CMAKE_INSTALL_PREFIX}/${spi_prefix}/TCL)

ec_install_prefix()  # Define install prefix  

find_package(TCL ${TCL_REQ_VERSION} REQUIRED)
if(TCL_FOUND)
   add_library(TCL::TCL SHARED IMPORTED)
   set_target_properties(TCL::TCL PROPERTIES IMPORTED_LOCATION ${TCL_LIBRARY} IMPORTED_NO_SONAME TRUE)
   target_include_directories(TCL::TCL INTERFACE ${TCL_INCLUDE_PATH})
   target_compile_definitions(TCL::TCL INTERFACE HAVE_TCL TCL_THREADS)
endif()

find_package(eerUtils ${EER_REQ_VERSION} CONFIG REQUIRED)
find_package(rmn ${rmn_REQ_VERSION} COMPONENTS shared) 
find_package(vgrid ${vgrid_REQ_VERSION} COMPONENTS shared)
find_package(GDAL ${GDAL_REQ_VERSION})
if(GDAL_FOUND)
   target_compile_definitions(GDAL::GDAL INTERFACE HAVE_GDAL)
endif()

if(${CMAKE_SYSTEM_PROCESSOR} EQUAL x86_64)
   add_compile_options(-fPIC -DSTDC_HEADERS)
endif()

add_compile_definitions(_${CMAKE_SYSTEM_NAME}_ TCL_THREADS _GNU_SOURCE _DEFAULT_SOURCE)
link_libraries("-Wl,--disable-new-dtags")

add_subdirectory(src src)

install(PROGRAMS bin/GenPhysX TYPE BIN)
install(DIRECTORY tcl/ DESTINATION tcl USE_SOURCE_PERMISSIONS) 
install(DIRECTORY doc/ DESTINATION doc USE_SOURCE_PERMISSIONS) 

# Packaging
ec_install_prefix(${NAME} ${PROJECT_VERSION} PACKAGE_PREFIX)  # Define package prefix  
ec_build_config()                                             # Create build configuration script
ec_prepare_ssm()                                              # Prepare ssm packaging files

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_VENDOR "ECCC")
set(CPACK_PACKAGE_CONTACT "${MAINTAINER}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/package")
set(CPACK_PACKAGE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(CPACK_PACKAGE_FILE_NAME "${PACKAGE_PREFIX}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}")
include(CPack)
