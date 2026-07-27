using GLib;

namespace ValaTux.Finder {
    public class Info : Object {
        public string path;
        public FileInfo file_info;
        public string ext;
        public string name;

        public Info (string path, FileInfo file_info) {
            this.path = path;
            this.file_info = file_info;

            string basename = Path.get_basename (path);
            this.ext = get_extension (basename);

            if (this.ext.length > 0) {
                this.name = basename.substring (0, basename.length - this.ext.length);
            } else {
                this.name = basename;
            }
        }

        private static string get_extension (string basename) {
            int dot_index = basename.last_index_of_char ('.');

            if (dot_index <= 0) {
                return "";
            }

            return basename.substring (dot_index);
        }
    }
}
