using Gee;
using GLib;

namespace ValaFoundation.Finder {
    private static uint string_hash (string key) {
        return str_hash (key);
    }

    private static bool string_equal (string a, string b) {
        return str_equal (a, b);
    }

    private static bool regex_match_any (string name, string[] patterns) {
        foreach (string pattern in patterns) {
            try {
                Regex regex = new Regex (pattern + "$", RegexCompileFlags.OPTIMIZE);
                if (regex.match (name)) {
                    return true;
                }
            } catch (Error error) {
            }
        }

        return false;
    }

    public enum Mode {
        DIR,
        FILE,
        ALL
    }

    public class Finder : Object {
        public ArrayList<string> dirs;
        public ArrayList<string> patterns;
        public HashMap<string, Info> files;
        public ArrayList<string> excludes;
        public Mode mode;
        public bool enabled_recursive;

        public Finder () {
            this.dirs = new ArrayList<string> ();
            this.patterns = new ArrayList<string> ();
            this.files = new HashMap<string, Info> (string_hash, string_equal);
            this.excludes = new ArrayList<string> ();
            this.mode = Mode.ALL;
            this.enabled_recursive = true;
        }

        public static Finder New () {
            return new Finder ();
        }

        public static string DirectoryHash (string path) throws Error {
            HashMap<string, string> files = DirectoryFilesHash (path);
            StringBuilder builder = new StringBuilder ();

            foreach (string key in files.keys) {
                builder.append (files.get (key));
            }

            return Checksum.compute_for_string (ChecksumType.MD5, builder.str);
        }

        public static HashMap<string, string> DirectoryFilesHash (string path) throws Error {
            HashMap<string, Info> files = new Finder ().Find (new string[] {"*"}).In (new string[] {path}).Get ();
            var result = new HashMap<string, string> (string_hash, string_equal);

            foreach (string key in files.keys) {
                Info info = files.get (key);

                if (info.file_info.get_file_type () == FileType.DIRECTORY) {
                    continue;
                }

                result.set (key, FileHash (key));
            }

            return result;
        }

        public static string FileHash (string path) throws Error {
            uint8[] contents;
            FileUtils.get_data (path, out contents);

            var checksum = new Checksum (ChecksumType.MD5);
            checksum.update (contents, (size_t) contents.length);
            return checksum.get_string ();
        }

        public Finder Recursive () {
            this.enabled_recursive = true;
            return this;
        }

        public Finder NotRecursive () {
            this.enabled_recursive = false;
            return this;
        }

        public Finder In (string[] dirs) {
            foreach (string dir in dirs) {
                this.dirs.add (dir);
            }

            return this;
        }

        public Finder Find (string[] patterns) {
            foreach (string pattern in patterns) {
                this.patterns.add (pattern);
            }

            this.mode = Mode.ALL;
            return this;
        }

        public Finder FindFiles (string[] patterns) {
            foreach (string pattern in patterns) {
                this.patterns.add (pattern);
            }

            this.mode = Mode.FILE;
            return this;
        }

        public Finder FindDirectories (string[] patterns) {
            foreach (string pattern in patterns) {
                this.patterns.add (pattern);
            }

            this.mode = Mode.DIR;
            return this;
        }

        public Finder Exclude (string[] patterns) {
            foreach (string pattern in patterns) {
                this.excludes.add (pattern);
            }

            return this;
        }

        public HashMap<string, Info> Get () {
            this.search ();
            return this.files;
        }

        public HashMap<string, Info> Match (string[] patterns) {
            var result = new HashMap<string, Info> (string_hash, string_equal);

            foreach (string key in this.Get ().keys) {
                if (regex_match_any (key, patterns)) {
                    result.set (key, this.files.get (key));
                }
            }

            return result;
        }

        private void search () {
            this.files = new HashMap<string, Info> (string_hash, string_equal);

            foreach (string dir in this.dirs) {
                if (this.enabled_recursive) {
                    this.scan_directory (dir, true);
                } else {
                    this.scan_directory (dir, false);
                }
            }
        }

        private void scan_directory (string dir, bool include_root) {
            File file = File.new_for_path (dir);

            try {
                if (include_root) {
                    FileInfo root_info = file.query_info ("standard::*", FileQueryInfoFlags.NONE);
                    this.add_info (dir, root_info);

                    if (root_info.get_file_type () != FileType.DIRECTORY) {
                        return;
                    }
                }

                FileEnumerator enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE);
                FileInfo child_info;

                while ((child_info = enumerator.next_file ()) != null) {
                    string child_path = Path.build_filename (dir, child_info.get_name ());
                    this.add_info (child_path, child_info);

                    if (this.enabled_recursive && child_info.get_file_type () == FileType.DIRECTORY) {
                        this.scan_directory (child_path, true);
                    }
                }
            } catch (Error error) {
                warning ("error while reading dir: %s", error.message);
            }
        }

        private void add_info (string path, FileInfo info) {
            Info? created = this.create_info (path, info);

            if (created != null) {
                this.files.set (path, created);
            }
        }

        private Info? create_info (string path, FileInfo info) {
            if (!this.matches_pattern (path, this.excludes) &&
                this.matches_pattern (path, this.patterns) &&
                (this.mode == Mode.ALL ||
                 (this.mode == Mode.DIR && info.get_file_type () == FileType.DIRECTORY) ||
                 (this.mode == Mode.FILE && info.get_file_type () != FileType.DIRECTORY))) {
                return new Info (path, info);
            }

            return null;
        }

        private bool matches_pattern (string file, ArrayList<string> patterns) {
            if (patterns.size == 0) {
                return false;
            }

            string basename = Path.get_basename (file);

            foreach (string pattern in patterns) {
                if (glob_match (pattern, basename)) {
                    return true;
                }
            }

            return false;
        }

        private static bool glob_match (string pattern, string text) {
            try {
                Regex regex = new Regex ("^" + glob_to_regex (pattern) + "$", RegexCompileFlags.OPTIMIZE);
                return regex.match (text);
            } catch (Error error) {
                return false;
            }
        }

        private static string glob_to_regex (string pattern) {
            StringBuilder builder = new StringBuilder ();

            for (int i = 0; i < pattern.length; i++) {
                unichar ch = pattern.get_char (i);

                switch (ch) {
                case '*':
                    builder.append (".*");
                    break;
                case '?':
                    builder.append (".");
                    break;
                case '.':
                case '+':
                case '(':
                case ')':
                case '|':
                case '^':
                case '$':
                case '{':
                case '}':
                case '[':
                case ']':
                case '\\':
                    builder.append_c ('\\');
                    builder.append_unichar (ch);
                    break;
                default:
                    builder.append_unichar (ch);
                    break;
                }
            }

            return builder.str;
        }
    }

    public Finder New () {
        return Finder.New ();
    }

    public Finder Find (string[] patterns) {
        return new Finder ().Find (patterns);
    }

    public Finder FindFiles (string[] patterns) {
        return new Finder ().FindFiles (patterns);
    }

    public Finder FindDirectories (string[] patterns) {
        return new Finder ().FindDirectories (patterns);
    }

    public Finder In (string[] dirs) {
        return new Finder ().In (dirs);
    }

    public string DirectoryHash (string path) throws Error {
        return Finder.DirectoryHash (path);
    }

    public HashMap<string, string> DirectoryFilesHash (string path) throws Error {
        return Finder.DirectoryFilesHash (path);
    }

    public string FileHash (string path) throws Error {
        return Finder.FileHash (path);
    }

    public bool Match (string name, string[] patterns) {
        return regex_match_any (name, patterns);
    }
}
