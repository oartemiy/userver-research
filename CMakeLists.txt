cmake_minimum_required(VERSION 3.12...3.31)
project(research CXX)

option(
    RESEARCH_USE_PCH
    "Precompile common userver/protobuf headers (build-time experiment)"
    OFF
)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(DownloadUserver)

find_package(
    userver
    COMPONENTS core #
               grpc
               mongo
               postgresql
    QUIET
)
if(NOT userver_FOUND)
    # Tries TRY_DIR first, falls back to downloading userver from GitHub using CPM.
    download_userver(TRY_DIR third_party/userver)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-ftime-trace)
endif()

userver_setup_environment()

# Common sources
include_directories(src)

add_library(
    ${PROJECT_NAME}_objs OBJECT
    src/greeting.cpp #
    src/hello.cpp #
    src/hello_postgres.cpp
    src/hello_mongo.cpp
    src/hello_grpc.cpp
)
target_link_libraries(
    ${PROJECT_NAME}_objs
    PUBLIC userver::core #
           userver::grpc
           userver::mongo
           userver::postgresql
)

userver_add_grpc_library(${PROJECT_NAME}_proto PROTOS handlers/hello.proto)
target_link_libraries(${PROJECT_NAME}_objs PUBLIC ${PROJECT_NAME}_proto)

# The Service
add_executable(${PROJECT_NAME} src/main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_objs)

# Unit Tests
add_executable(${PROJECT_NAME}_unittest src/greeting_test.cpp)
target_link_libraries(${PROJECT_NAME}_unittest PRIVATE ${PROJECT_NAME}_objs userver::utest)
add_google_tests(${PROJECT_NAME}_unittest)

# Benchmarks
add_executable(${PROJECT_NAME}_benchmark src/greeting_benchmark.cpp)
target_link_libraries(${PROJECT_NAME}_benchmark PRIVATE ${PROJECT_NAME}_objs userver::ubench)
add_google_benchmark_tests(${PROJECT_NAME}_benchmark)

# Build-time experiment (step 4 of the assignment): precompiled headers with
# the headers that are re-parsed in every translation unit.
# Enabled only via -DRESEARCH_USE_PCH=ON, see scripts/measure.sh.
if(RESEARCH_USE_PCH)
    target_precompile_headers(${PROJECT_NAME}_objs PRIVATE src/pch_userver.hpp)
    target_precompile_headers(${PROJECT_NAME} PRIVATE src/pch_userver.hpp)
    target_precompile_headers(${PROJECT_NAME}_proto PRIVATE src/pch_proto.hpp)
endif()

# Functional testing
userver_testsuite_add_simple()

# Install
include(GNUInstallDirs)

if(DEFINED ENV{PREFIX})
    message(STATUS "Set install prefix: $ENV{PREFIX}")
    file(TO_CMAKE_PATH "$ENV{PREFIX}" PREFIX_PATH)
    set(CMAKE_INSTALL_PREFIX "${PREFIX_PATH}")
endif()

file(GLOB CONFIGS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/configs/*.yaml ${CMAKE_CURRENT_SOURCE_DIR}/configs/*.json)

install(
    TARGETS ${PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT ${PROJECT_NAME}
)
install(
    FILES ${CONFIGS_FILES}
    DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/${PROJECT_NAME}
    COMPONENT ${PROJECT_NAME}
)