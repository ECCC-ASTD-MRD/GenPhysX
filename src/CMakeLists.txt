message(STATUS "Generating libTclGeoPhy librairie")

file(GLOB PROJECT_INCLUDE_FILES generic/*.h)
file(GLOB PROJECT_SOURCE_FILES generic/*.c generic/*.f)

set(NAME "TclGeoPhy")
add_library(${NAME} SHARED ${PROJECT_INCLUDE_FILES} ${PROJECT_SOURCE_FILES})

#----- Compilation  stuff
set_target_properties(${NAME} PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(${NAME} PROPERTIES PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}")
target_compile_definitions(${NAME} PRIVATE PACKAGE_NAME=\"${NAME}\" PACKAGE_VERSION=\"${VERSION}\")
target_include_directories(${NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/generic)

add_dependencies(${NAME} GenPhysX_build_info)

#----- Required libs
target_link_libraries(${NAME} eerUtils::eerUtils)

#----- Optional libs
ec_target_link_library_if(${NAME} RMN_FOUND              RMN::RMN)
ec_target_link_library_if(${NAME} VGRID_FOUND            VGRID::VGRID)
ec_target_link_library_if(${NAME} GDAL_FOUND             GDAL::GDAL)

target_link_libraries(${NAME} TCL::TCL)

#----- RPATH handling
ec_target_rpath_from_libs(${NAME})

install(TARGETS ${NAME}
   LIBRARY DESTINATION TCL/lib/${NAME}${VERSION}
   PUBLIC_HEADER DESTINATION TCL/include)

ec_build_tcl_pkgindex()

