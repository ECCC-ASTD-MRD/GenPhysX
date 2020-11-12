message(STATUS "Generating libTclGeoPhy librairie")

file(GLOB PROJECT_INCLUDE_FILES generic/*.h)
file(GLOB PROJECT_SOURCE_FILES generic/*.c generic/*.f)

add_library(${NAME} SHARED ${PROJECT_INCLUDE_FILES} ${PROJECT_SOURCE_FILES})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/generic)
add_compile_definitions(PACKAGE_NAME=\"${NAME}\" PACKAGE_VERSION=\"${VERSION}\")

set_target_properties(${NAME} PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(${NAME} PROPERTIES PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}")

add_dependencies(${NAME} build_info)

if (EER_FOUND) 
   target_link_libraries(${NAME} ${EER_LIBRARIES})
endif()

if (RMN_FOUND) 
   target_link_libraries(${NAME} ${RMN_LIBRARIES})
endif()

#if(VGRID_FOUND)
#   target_link_libraries(${NAME} ${VGRID_LIBRARIES})
#endif()

if(GDAL_FOUND)
   target_link_libraries(${NAME} ${GDAL_LIBRARIES})
endif()

target_link_libraries(${NAME} ${TCL_LIBRARIES})

install(TARGETS ${NAME}
   LIBRARY DESTINATION TCL/lib/${NAME}${VERSION}
   PUBLIC_HEADER DESTINATION TCL/include)

include(ec_build_tcl_pkgindex)