namespace AppTests {
    using GLib;
    using ValaFoundation.Finder;
    using ValaFoundation.Testcases;

    public class FinderTest : BaseTest {
        construct {
            add_test ("find-files-recursive", test_find_files_recursive);
            add_test ("find-files-non-recursive", test_find_files_non_recursive);
            add_test ("find-directories", test_find_directories_mode);
            add_test ("exclude-pattern", test_exclude_pattern);
            add_test ("match-regex", test_match_regex);
            add_test ("info-name-ext", test_info_name_and_extension);
        }

        private string create_fixture_tree () {
            string root = "";

            try {
                root = DirUtils.make_tmp ("finder-tests-XXXXXX");
                string nested = Path.build_filename (root, "nested");

                DirUtils.create_with_parents (nested, 0755);

                FileUtils.set_contents (Path.build_filename (root, "root.txt"), "root");
                FileUtils.set_contents (Path.build_filename (root, "root.log"), "log");
                FileUtils.set_contents (Path.build_filename (nested, "inner.txt"), "inner");
            } catch (Error error) {
                assert_not_reached ();
            }

            return root;
        }

        private void remove_tree (File node) {
            try {
                if (node.query_file_type (FileQueryInfoFlags.NONE) == FileType.DIRECTORY) {
                    FileEnumerator enumerator = node.enumerate_children (
                        "standard::name,standard::type",
                        FileQueryInfoFlags.NONE
                    );
                    FileInfo info;

                    while ((info = enumerator.next_file ()) != null) {
                        remove_tree (node.get_child (info.get_name ()));
                    }
                }

                node.delete ();
            } catch (Error error) {
            }
        }

        public void test_find_files_recursive () {
            string root = create_fixture_tree ();
            var result = FindFiles ({"*.txt"}).In ({root}).Get ();

            assert (result.has_key (Path.build_filename (root, "root.txt")));
            assert (result.has_key (Path.build_filename (root, "nested", "inner.txt")));
            assert (!result.has_key (Path.build_filename (root, "root.log")));

            remove_tree (File.new_for_path (root));
        }

        public void test_find_files_non_recursive () {
            string root = create_fixture_tree ();
            var result = FindFiles ({"*.txt"}).NotRecursive ().In ({root}).Get ();

            assert (result.has_key (Path.build_filename (root, "root.txt")));
            assert (!result.has_key (Path.build_filename (root, "nested", "inner.txt")));

            remove_tree (File.new_for_path (root));
        }

        public void test_find_directories_mode () {
            string root = create_fixture_tree ();
            var result = FindDirectories ({"*"}).In ({root}).Get ();

            assert (result.has_key (root));
            assert (result.has_key (Path.build_filename (root, "nested")));
            assert (!result.has_key (Path.build_filename (root, "root.txt")));

            remove_tree (File.new_for_path (root));
        }

        public void test_exclude_pattern () {
            string root = create_fixture_tree ();
            var result = FindFiles ({"*.txt"}).Exclude ({"inner.*"}).In ({root}).Get ();

            assert (result.has_key (Path.build_filename (root, "root.txt")));
            assert (!result.has_key (Path.build_filename (root, "nested", "inner.txt")));

            remove_tree (File.new_for_path (root));
        }

        public void test_match_regex () {
            string root = create_fixture_tree ();
            Finder finder = FindFiles ({"*.txt"}).In ({root});
            var matched = finder.Match ({".*inner\\.txt"});

            assert (!matched.has_key (Path.build_filename (root, "root.txt")));
            assert (matched.has_key (Path.build_filename (root, "nested", "inner.txt")));

            remove_tree (File.new_for_path (root));
        }

        public void test_info_name_and_extension () {
            string root = create_fixture_tree ();
            var result = FindFiles ({"root.txt"}).In ({root}).Get ();
            string key = Path.build_filename (root, "root.txt");
            Info info = result.get (key);

            assert (info.name == "root");
            assert (info.ext == ".txt");

            remove_tree (File.new_for_path (root));
        }
    }
}
