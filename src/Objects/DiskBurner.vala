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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

     	static DiskBurner _instance = null;
        public static DiskBurner instance {
            get {
                if (_instance == null)
                    _instance = new DiskBurner ();
                return _instance;
            }
        }

		private DiskBurner () {}

        construct {
            this.is_running = false;
            this.begin.connect (() => {
                this.is_running = true;
                debug ("begin");
            });
            this.finished.connect (() => {
                this.is_running = false;
                debug ("finished");
            });
            this.canceled.connect (() => {
                this.is_running = false;
                debug ("canceled");
            });
        }

        public bool is_running {get;set;}

        public signal void begin ();
        public signal void finished ();
        public signal void canceled ();
        public signal void progress (double percent);

        File current_image;
        uint64 image_size;
        int last_progress = 0;
        Pid child_pid;

        public async void flash_image (File image, Drive drive) {
            current_image = image;

            try {
                image_size = current_image.query_info ("standard::size", 0).get_size ();
            } catch (GLib.Error e) {
                stdout.printf ("GLibError: %s\n", e.message);
                image_size = 0;
            }

            string if_arg = "if=" + current_image.get_path ();
            string of_arg = "of=" + drive.get_identifier ("unix-device");

            debug (if_arg);
            debug (of_arg);

            string[] spawn_args = {"pkexec", "dd", if_arg, of_arg, "bs=1M", "conv=sync", "status=progress"};

            int standard_error = 0;
            try {
	            Process.spawn_async_with_pipes ("/",
		            spawn_args,
		            null,
		            SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
		            null,
		            out child_pid,
		            null,
		            null,
		            out standard_error);
            } catch (GLib.SpawnError e) {
                stdout.printf ("GLibSpawnError: %s\n", e.message);
            }

            IOChannel error = new IOChannel.unix_new (standard_error);
	        error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                if (condition == IOCondition.HUP) {
                    return false;
                }

                try {
                    string line;
                    channel.read_line (out line, null, null);
                    double current_size = get_current_size (line);
                    int percent = (int)(current_size * 100 / image_size);
                    if (percent != last_progress) {
                        last_progress = percent;
                        progress (((double)percent) / 100);
                    }
                } catch (IOChannelError e) {
                    stdout.printf ("IOChannelError: %s\n", e.message);
                    return false;
                } catch (ConvertError e) {
                    stdout.printf ("ConvertError: %s\n", e.message);
                    return false;
                }

                return true;
	        });

            ChildWatch.add (child_pid, (pid, status) => {
		        Process.close_pid (pid);

                if (last_progress > 0) {
                    finished ();
                } else {
                    canceled ();
                }

                last_progress = 0;
	        });

            begin ();
        }

        private double get_current_size (string line) {
            MatchInfo  match_info;
            try {
                Regex regex = new Regex ("^[0-9]*");
                if (regex.match (line, 0, out match_info)) {
                    return double.parse (match_info.fetch_all () [0]);
                }
            } catch (GLib.RegexError e) {
                stdout.printf ("GLibRegexError: %s\n", e.message);
            }
            return 0;
        }
    }
}
