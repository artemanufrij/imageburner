/*-
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace Imageburner {
    public class DeviceManager : GLib.Object {
        static DeviceManager _instance = null;

        public static DeviceManager instance {
            get {
                if (_instance == null)
                    _instance = new DeviceManager ();
                return _instance;
            }
        }

        private DeviceManager () {
        }

        public signal void drive_connected (Drive drive);
        public signal void drive_disconnected (Drive drive);

        private GLib.VolumeMonitor monitor;

        construct {
            monitor = GLib.VolumeMonitor.get ();

            monitor.drive_connected.connect (
                (drive) => {
                    if (valid_device (drive)) {
                        drive_connected (drive);
                    }
                });

            monitor.drive_disconnected.connect (
                (drive) => {
                    drive_disconnected (drive);
                });

            monitor.volume_added.connect (
                (volume) => {
                    if (valid_device (volume.get_drive ())) {
                        drive_connected (volume.get_drive ());
                    }
                });

            monitor.volume_removed.connect (
                (volume) => {
                    if (volume.get_drive () != null) {
                        drive_disconnected (volume.get_drive ());
                    }
                });
        }

        public void init () {
            GLib.List<GLib.Drive> drives = monitor.get_connected_drives ();
            foreach (Drive drive in drives) {
                if (valid_device (drive)) {
                    drive_connected (drive);
                }
            }
        }

        private bool valid_device (Drive drive) {
            string ? unix_device = drive.get_identifier ("unix-device");
            stdout.printf ("%s removable: %s; can stop: %s\n", unix_device, drive.is_media_removable ().to_string (), drive.can_stop ().to_string ());
            return (drive.is_media_removable () || drive.can_stop ()) && drive.has_media () && (unix_device != null && (unix_device.has_prefix ("/dev/sd") || unix_device.has_prefix ("/dev/mmc") || unix_device.has_prefix ("/dev/nvm")));
        }
    }
}
