message(STATUS "Generating libTclGeoPhy librairie")

file(GLOB PROJECT_INCLUDE_FILES generic/*.h)
file(GLOB PROJECT_SOURCE_FILES generic/*.c generic/*.f)

set(NAME "TclGeoPhy")
add_library(${NAME} SHARED ${PROJECT_INCLUDE_FILES} ${PROJECT_SOURCE_FILES})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/generic)
add_compile_definitions(PACKAGE_NAME=\"${NAME}\" PACKAGE_VERSION=\"${VERSION}\")
set_target_properties(${NAME} PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(${NAME} PROPERTIES PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}")

add_dependencies(${NAME} GenPhysX_build_info)

target_link_libraries(${NAME} eerUtils::eerUtils)

#----- Optional libs
ec_target_link_library_if(${NAME} RMN_FOUND              RMN::RMN)
ec_target_link_library_if(${NAME} VGRID_FOUND            VGRID::VGRID)
ec_target_link_library_if(${NAME} GDAL_FOUND             GDAL::GDAL)

target_link_libraries(${NAME} TCL::TCL)
#target_include_directories(${NAME} PUBLIC ${SPI_ROOT}/include)

install(TARGETS ${NAME}
   LIBRARY DESTINATION TCL/lib/${NAME}${VERSION}
   PUBLIC_HEADER DESTINATION TCL/include)

include(ec_build_tcl_pkgindex)
ec_build_tcl_pkgindex()

