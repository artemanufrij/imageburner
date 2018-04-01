/*-
 * Copyright (c) 2017-2018 Artem Anufrij <artem.anufrij@live.de>
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
    public class DiskBurner : GLib.Object {
        public signal void begin ();
        public signal void finished ();

        static DiskBurner _instance = null;
        public static DiskBurner instance {
            get {
                if (_instance == null) {
                    _instance = new DiskBurner ();
                }
                return _instance;
            }
        }

        private DiskBurner () {
        }

        construct {
            is_running = false;
            begin.connect (
                () => {
                    is_running = true;
                });
            finished.connect (
                () => {
                    is_running = false;
                });
        }

        public bool is_running { get; private set; }

        public void flash_image (File image, Drive drive) {
            begin ();

            new Thread<void*> (
                "flash_image",
                () => {
                    string if_arg = "if=" + image.get_path ();
                    string of_arg = "of=" + drive.get_identifier ("unix-device");

                    string[] spawn_args = {"pkexec", "dd", if_arg, of_arg, "bs=4M"};
                    string[] spawn_env = Environ.get ();

                    try {
                        Process.spawn_sync (
                            "/",
                            spawn_args,
                            spawn_env,
                            SpawnFlags.SEARCH_PATH,
                            null,
                            null,
                            null,
                            null);
                    } catch (GLib.SpawnError e) {
                        warning ("GLibSpawnError: %s\n", e.message);
                    }

                    finished ();
                    return null;
                });
        }
    }
}
