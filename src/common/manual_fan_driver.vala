namespace VictusControl {
    /**
     * One kernel interface for manual fan levels.
     *
     * Levels are expressed in `unit` (FAN_LEVEL_UNIT_RPM or
     * FAN_LEVEL_UNIT_PERCENT) and travel unchanged over D-Bus.
     */
    public interface ManualFanDriver : Object {
        public abstract string unit { get; }

        /* True when firmware forgets the levels unless userspace rewrites them. */
        public abstract bool needs_reapply { get; }

        public abstract bool is_available (string hwmon_dir);

        public abstract int level_max (string hwmon_dir, uint16 fan);

        /* Level the driver reports now, in `unit`; -1 when unreadable. */
        public abstract int current_level (string hwmon_dir, uint16 fan);

        public abstract void apply_levels (string hwmon_dir, uint16 fan1, uint16 fan2) throws Error;
    }
}
