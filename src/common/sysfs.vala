namespace VictusControl {
    public class Fs : Object {
        public static bool exists (string path) {
            return FileUtils.test(path, FileTest.EXISTS);
        }

        public static string? read_text (string path) {
            try {
                string contents;
                FileUtils.get_contents(path, out contents);
                return contents.strip();
            } catch (Error error) {
                return null;
            }
        }

        public static int read_int (string path, int fallback = -1) {
            var text = read_text(path);
            if (text == null) {
                return fallback;
            }
            try {
                return int.parse(text);
            } catch (Error error) {
                return fallback;
            }
        }

        public static void write_text (string path, string contents) throws Error {
            var stream = FileStream.open(path, "w");
            if (stream == null) {
                throw new FileError.FAILED("Unable to open %s for writing".printf(path));
            }

            if (stream.puts("%s\n".printf(contents)) == FileStream.EOF) {
                throw new FileError.FAILED("Failed to write %s".printf(path));
            }
        }

        public static string[] list_directories (string path) {
            var list = new Gee.ArrayList<string>();
            try {
                var file = File.new_for_path(path);
                var enumerator = file.enumerate_children(
                    "%s,%s".printf(FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_TYPE),
                    FileQueryInfoFlags.NONE
                );
                FileInfo info;
                while ((info = enumerator.next_file()) != null) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        list.add(Path.build_filename(path, info.get_name()));
                    }
                }
            } catch (Error error) {
            }
            return list.to_array();
        }

        public static string[] list_files (string path) {
            var list = new Gee.ArrayList<string>();
            try {
                var file = File.new_for_path(path);
                var enumerator = file.enumerate_children(
                    "%s,%s".printf(FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_TYPE),
                    FileQueryInfoFlags.NONE
                );
                FileInfo info;
                while ((info = enumerator.next_file()) != null) {
                    if (info.get_file_type() == FileType.REGULAR) {
                        list.add(Path.build_filename(path, info.get_name()));
                    }
                }
            } catch (Error error) {
            }
            return list.to_array();
        }

        public static bool ensure_parent_dir (string path) {
            var parent = Path.get_dirname(path);
            if (parent == null || parent == ".") {
                return true;
            }
            return DirUtils.create_with_parents(parent, 0x1ED) == 0;
        }

        public static string now_iso8601_utc () {
            return new DateTime.now_utc().format("%FT%TZ");
        }
    }
}
