using GLib;
using Gee;

int main (string[] args) {

    ValaTux.Testcases.BaseTest.saved_commands = new Gee.ArrayList<ValaTux.Testcases.TestCommand> ();
    Test.init (ref args);

    ValaTux.Testcases.register_test_suite<AppTests.ExampleTest> ();
    ValaTux.Testcases.register_test_suite<AppTests.FinderTest> ();


    return Test.run ();
}
