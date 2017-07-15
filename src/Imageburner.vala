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

    public class ImageburnerApp : Granite.Application {
        static ImageburnerApp _instance = null;

        public static ImageburnerApp instance {
            get {
                if (_instance == null)
                    _instance = new ImageburnerApp ();
                return _instance;
            }
        }

        public Gtk.Window mainwindow;
        Gtk.Grid content;
        Gtk.Button open_image;

        Gtk.Image device_logo;
        Gtk.FlowBox device_list;
        Gtk.Popover device_popover;
        Gtk.Button select_device;

        Gtk.Button process_start;
        Gtk.ProgressBar bar;

        File _selected_image = null;
        File selected_image {
            get { return _selected_image; }
            set {
                _selected_image = value;
                this.select_device.sensitive = selected_image != null;
                this.process_start.sensitive = selected_device != null && selected_image != null;

                this.open_image.label = _("Image");
                if (selected_image != null) {
                    this.open_image.label = selected_image.get_basename ();
                }
            }
        }

        Imageburner.Device _selected_device = null;
        Imageburner.Device selected_device {
            get { return _selected_device; }
            set {
                if (selected_device == value) {
                    return;
                }
                _selected_device = value;
                this.process_start.sensitive = selected_device != null && selected_image != null;

                this.select_device.label = _("Device");
                if (selected_device != null) {
                    this.select_device.label = selected_device.drive.get_name ();
                    if (selected_device.is_card) {
                        this.device_logo.set_from_icon_name ("media-flash", Gtk.IconSize.DIALOG);
                    } else {
                        this.device_logo.set_from_gicon (selected_device.drive.get_icon (), Gtk.IconSize.DIALOG);
                    }
                }
            }
        }

        Imageburner.DeviceManager devices;
        Imageburner.DiskBurner burner;

        construct {
            program_name = "Imageburner";
            exec_name = "imageburner";
        }

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }

            devices = DeviceManager.instance;
            devices.drive_connected.connect (device_added);
            devices.drive_disconnected.connect (device_removed);

            burner = DiskBurner.instance;
            burner.begin.connect (() => {
                bar.set_fraction (0);
                bar.show_all ();

                open_image.sensitive = false;
                select_device.sensitive = false;
                process_start.sensitive = false;

            });
            burner.end.connect (() => {
                bar.visible = false;
                open_image.sensitive = true;
                select_device.sensitive = true;
                process_start.sensitive = true;
            });
            burner.progress.connect ((val) => {
                debug ("percent: %f", val);
                bar.set_fraction (val);
                bar.set_text ("%d %".printf ((int)(val * 100)));
                bar.show_all ();
            });

            this.build_ui ();
            devices.init ();

            Gtk.main ();
        }

        private void build_ui () {
            mainwindow = new Gtk.Window ();
            mainwindow.title = _("Imageburner");
            mainwindow.set_resizable (false);
            mainwindow.destroy.connect (() => {
                Gtk.main_quit ();
            });

            content = new Gtk.Grid ();
            content.margin = 48;
            content.hexpand = true;
            content.column_spacing = 32;
            content.row_spacing = 24;

            build_image_area ();

            build_device_area ();

            build_flash_area ();

            // PROGRESS BAR
            bar = new Gtk.ProgressBar ();
            bar.set_show_text (true);
            content.attach (bar, 0, 1, 3, 1);

            mainwindow.add (content);
            mainwindow.show_all ();

            bar.visible = false;
        }

        private void build_image_area () {
            var grid = new Gtk.Grid ();
            grid.row_spacing = 24;
            grid.width_request = 200;
            var image_logo = new Gtk.Image.from_icon_name ("folder-open", Gtk.IconSize.DIALOG);
            grid.attach (image_logo, 0, 0, 1, 1);

            open_image = new Gtk.Button.with_label (_("Image"));
            open_image.expand = true;
            open_image.clicked.connect (select_image);
            grid.attach (open_image, 0, 1, 1, 1);

            content.attach (grid, 0, 0, 1, 1);
        }

        private void build_device_area () {
            var grid = new Gtk.Grid ();
            grid.row_spacing = 24;
            grid.width_request = 200;
            device_list = new Gtk.FlowBox ();
            device_list.child_activated.connect (select_drive);

            device_logo = new Gtk.Image.from_icon_name ("drive-removable-media-usb", Gtk.IconSize.DIALOG);
            grid.attach (device_logo, 0, 0, 1, 1);

            select_device = new Gtk.Button.with_label (_("Device"));
            select_device.expand = true;
            select_device.sensitive = false;
            select_device.clicked.connect (() => {
                device_popover.visible = !device_popover.visible;
            });

            device_popover = new Gtk.Popover (select_device);
            device_popover.position = Gtk.PositionType.TOP;
            device_popover.add (device_list);
            device_popover.show.connect (() => {
                device_list.select_child (selected_device);
                select_device.grab_focus ();
            });
            grid.attach (select_device, 0, 1, 1, 1);

            content.attach (grid, 1, 0, 1, 1);
        }

        private void build_flash_area () {
            var grid = new Gtk.Grid ();
            grid.row_spacing = 24;
            grid.width_request = 200;
            var start_logo = new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.DIALOG);
            grid.attach (start_logo, 0, 0, 1, 1);

            process_start = new Gtk.Button.with_label (_("Flash"));
            process_start.get_style_context ().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            process_start.expand = true;
            process_start.sensitive = false;
            process_start.valign = Gtk.Align.CENTER;
            process_start.clicked.connect (flash_image);
            grid.attach (process_start, 0, 1, 1, 1);

            content.attach (grid, 2, 0, 1, 1);
        }

        private void select_image () {
            var file = new Gtk.FileChooserDialog (
                _("Open"), mainwindow,
                Gtk.FileChooserAction.OPEN,
                _("_Cancel"), Gtk.ResponseType.CANCEL,
                _("_Open"), Gtk.ResponseType.ACCEPT);

            var image_filter = new Gtk.FileFilter ();
            image_filter.set_filter_name (_("Image files"));
            image_filter.add_mime_type ("application/x-iso9660-image");

            file.add_filter (image_filter);

            if (file.run () == Gtk.ResponseType.ACCEPT) {
                selected_image = file.get_file ();
                debug (file.get_filename ());
            }

            file.destroy();
        }

        private void select_drive (Gtk.FlowBoxChild item) {
            debug ("Selected: %s", (item as Imageburner.Device).drive.get_name ());
            this.selected_device = item as Imageburner.Device;
        }

        private void flash_image () {
            if (!burner.is_running) {
                burner.flash_image.begin (selected_image, selected_device);
            }
        }

        private void device_added (GLib.Drive drive) {
            debug ("Add device into list");
            var item = new Imageburner.Device (drive);
            this.selected_device = item;
            this.device_list.add (item);
            this.device_list.show_all ();
        }

        private void device_removed (GLib.Drive drive) {
            debug ("Remove device from list");
            foreach (var child in this.device_list.get_children ()) {
                if ((child as Device).drive == drive) {
                    this.device_list.remove (child);
                }
            }
            if (selected_device.drive == drive) {
                if (this.device_list.get_children ().length () > 0)
                selected_device = this.device_list.get_children ().last ().data as Device;
            }
        }
    }
}

public static int main (string [] args) {
    Gtk.init (ref args);
    var app = Imageburner.ImageburnerApp.instance;
    return app.run (args);
}
