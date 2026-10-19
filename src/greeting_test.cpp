#include <greeting.hpp>

#include <userver/utest/utest.hpp>

using research::UserType;

UTEST(SayHelloTo, Basic) {
    EXPECT_EQ(research::SayHelloTo("Developer", UserType::kFirstTime), "Hello, Developer!\n");
    EXPECT_EQ(research::SayHelloTo({}, UserType::kFirstTime), "Hello, unknown user!\n");

    EXPECT_EQ(research::SayHelloTo("Developer", UserType::kKnown), "Hi again, Developer!\n");
    EXPECT_EQ(research::SayHelloTo({}, UserType::kKnown), "Hi again, unknown user!\n");
}