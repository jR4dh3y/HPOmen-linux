namespace VictusControl {
    /**
     * Reads CPU, GPU, and peak temperatures from every hwmon device.
     */
    public class ThermalReader : Object {
        private const int MAX_TEMP_CHANNELS = 10;

        public static void read (Snapshot snapshot) {
            int max_temp = -1;
            foreach (var hwmon_dir in Fs.list_directories("/sys/class/hwmon")) {
                var name = Fs.read_text(Path.build_filename(hwmon_dir, "name")) ?? "";
                for (int index = 1; index <= MAX_TEMP_CHANNELS; index++) {
                    var path = Path.build_filename(hwmon_dir, "temp%d_input".printf(index));
                    if (!Fs.exists(path)) {
                        continue;
                    }
                    var milli_c = Fs.read_int(path);
                    if (milli_c < 0) {
                        continue;
                    }
                    var temp_c = milli_c / 1000;
                    if (temp_c > max_temp) {
                        max_temp = temp_c;
                    }
                    if (name == "k10temp" && snapshot.cpu_temp_c < 0) {
                        snapshot.cpu_temp_c = temp_c;
                    }
                    if (name == "amdgpu" && snapshot.gpu_temp_c < 0) {
                        snapshot.gpu_temp_c = temp_c;
                    }
                }
            }
            snapshot.max_temp_c = max_temp;
            snapshot.can_read_temp = max_temp >= 0;
        }
    }
}
