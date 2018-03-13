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
    public class Device : Gtk.FlowBoxChild  {

        Gtk.Grid content;
        Gtk.Image icon;
        Gtk.Label title;

        public GLib.Drive drive { get; private set; }

        construct {
            content = new Gtk.Grid ();
            content.row_spacing = 12;
            content.valign = Gtk.Align.CENTER;
            this.add (content);
        }

        public Device (GLib.Drive d) {
            this.drive = d;

            icon = get_medium_icon ();
            icon.margin = 6;
            title = new Gtk.Label (d.get_name ());
            title.margin_right = 6;
            content.attach (icon, 0, 0, 1, 1);
            content.attach (title, 1, 0, 1, 1);
        }

        // PROPERTIES
        public bool is_card {
            get {
                string unix_device = drive.get_identifier ("unix-device");
                return unix_device.index_of ("/dev/mmc") == 0;
            }
        }

        // METHODS
        public string get_unix_device () {
            return drive.get_identifier ("unix-device");
        }

        public Gtk.Image get_medium_icon () {
            if (is_card) {
                return new Gtk.Image.from_icon_name ("media-flash", Gtk.IconSize.LARGE_TOOLBAR);
            }
            return new Gtk.Image.from_gicon (drive.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        }

        public Gtk.Image get_large_icon () {
            if (is_card) {
                return new Gtk.Image.from_icon_name ("media-flash", Gtk.IconSize.DIALOG);
            }
            return new Gtk.Image.from_gicon (drive.get_icon (), Gtk.IconSize.DIALOG);
        }

        public void umount_all_volumes () {
            foreach (var volume in drive.get_volumes ()) {
                debug ("volume: %s", volume.get_name ());
                var mount = volume.get_mount ();

                if (mount != null) {
                    debug ("umount %s", mount.get_name ());
                    mount.unmount_with_operation.begin (GLib.MountUnmountFlags.FORCE, null);
                }
            }
        }
    }
}
