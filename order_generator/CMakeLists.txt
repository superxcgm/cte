CMAKE_MINIMUM_REQUIRED(VERSION 3.10)
project(order_generator)

include_directories(./include)

add_library(${PROJECT_NAME} src/order_generator.cc)

find_package(cdcf)
add_executable(create_orders src/create_orders.cc ../common/src/database_interface.cc)
target_link_libraries(create_orders order_generator cdcf::cdcf)

add_executable(create_initial_prices src/create_initial_prices.cc)
target_link_libraries(create_initial_prices order_generator)

add_executable(${PROJECT_NAME}_test src/order_generator_test.cc)
find_package(GTest REQUIRED)
target_link_libraries(${PROJECT_NAME}_test GTest::GTest order_generator)
enable_testing()
add_test(NAME ${PROJECT_NAME}_test COMMAND ${PROJECT_NAME}_test)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/src/create_initial_prices_config.json
        DESTINATION ${CMAKE_BINARY_DIR}/bin
        )
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/src/create_orders_config.json
        DESTINATION ${CMAKE_BINARY_DIR}/bin
        )