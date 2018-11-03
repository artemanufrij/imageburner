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
    public class MainWindow : Gtk.ApplicationWindow {
        public signal void calculate_begin ();
        public signal void calculate_finished (string result);

        Gtk.Grid content;
        Gtk.Button open_image;
        Gtk.Label image_name;
        Gtk.Grid image_container;

        Gtk.Image device_logo;
        Gtk.FlowBox device_list;
        Gtk.Popover device_popover;
        Gtk.Button select_device;
        Gtk.Label device_name;
        Gtk.Grid device_container;
        Gtk.HeaderBar headerbar;
        Gtk.ComboBoxText hash_chooser;
        Gtk.Spinner hash_waiting;
        Gtk.Spinner burning;
        Gtk.Image start_logo;

        Granite.Widgets.Toast app_notification;
        Notification desktop_notification;

        Gtk.Button flash_start;
        Gtk.Grid flash_container;
        Gtk.Label flash_label;

        File _selected_image = null;
        public File selected_image {
            get { return _selected_image; }
            set {
                _selected_image = value;
                this.device_container.sensitive = selected_image != null && has_removable_devices;
                this.flash_container.sensitive = selected_device != null && selected_image != null;

                if (selected_image != null) {
                    this.set_image_label (selected_image.get_basename ());
                    this.open_image.label = _ ("Change");
                } else {
                    this.set_image_label ("");
                    this.open_image.label = _ ("Open");
                }

                set_flash_label ();
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
                this.flash_container.sensitive = selected_device != null && selected_image != null;

                if (selected_device != null) {
                    this.set_device_label (selected_device.drive.get_name ());
                    this.select_device.label = _ ("Change");
                    if (selected_device.is_card) {
                        this.device_logo.set_from_icon_name ("media-flash", Gtk.IconSize.DIALOG);
                    } else {
                        this.device_logo.set_from_gicon (selected_device.drive.get_icon (), Gtk.IconSize.DIALOG);
                    }
                } else {
                    this.set_device_label ("");
                    this.select_device.label = _ ("Device");
                    this.device_logo.set_from_icon_name ("drive-removable-media-usb", Gtk.IconSize.DIALOG);
                }

                set_flash_label ();
            }
        }

        bool has_removable_devices {
            get {
                return this.device_list.get_children ().length () > 0;
            }
        }

        Imageburner.DeviceManager devices;
        Imageburner.DiskBurner burner;

        public MainWindow () {
            calculate_finished.connect (
                (result) => {
                    hash_waiting.active = false;
                    headerbar.title = result;
                    hash_chooser.sensitive = true;
                });
            calculate_begin.connect (
                () => {
                    hash_waiting.active = true;
                    headerbar.title = _ ("Calculating checksum…");
                    hash_chooser.sensitive = false;
                });
            this.resizable = false;

            this.build_ui ();

            devices = DeviceManager.instance;
            devices.drive_connected.connect (device_added);
            devices.drive_disconnected.connect (device_removed);

            burner = DiskBurner.instance;
            burner.begin.connect (
                () => {
                    image_container.sensitive = false;
                    device_container.sensitive = false;
                    flash_container.sensitive = false;
                    hash_chooser.sensitive = false;
                    burning.active = true;
                    start_logo.opacity = 0;
                    flash_label.label = _ ("please wait…");
                });
            burner.finished.connect (
                () => {
                    Idle.add (
                        () => {
                            image_container.sensitive = true;
                            device_container.sensitive = true;
                            flash_container.sensitive = true;
                            hash_chooser.sensitive = true;
                            burning.active = false;
                            start_logo.opacity = 1;
                            flash_label.label = _ ("Ready!");

                            var message = _ ("%s was written onto %s").printf (selected_image.get_basename (), selected_device.drive.get_name ());

                            if (is_active) {
                                app_notification.title = message;
                                app_notification.send_notification ();
                            } else {
                                desktop_notification.set_body (message);
                                application.send_notification ("notify.app", desktop_notification);
                            }

                            return false;
                        });
                });

            devices.init ();
            present ();
        }

        private void build_ui () {
            content = new Gtk.Grid ();
            content.margin = 32;
            content.column_spacing = 32;
            content.column_homogeneous = true;
            content.row_spacing = 24;

            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.title = _ ("Image Burner");
            this.set_titlebar (headerbar);

            hash_chooser = new Gtk.ComboBoxText ();
            hash_chooser.append ("MD5", "MD5");
            hash_chooser.append ("SHA256", "SHA256");
            hash_chooser.append ("SHA1", "SHA1");
            hash_chooser.active = 1;
            hash_chooser.tooltip_text = _ ("Choose an algorithm");
            hash_chooser.changed.connect (
                () => {
                    if (_selected_image != null) {
                        get_checksum.begin ();
                    }
                });
            headerbar.pack_end (hash_chooser);

            hash_waiting = new Gtk.Spinner ();
            headerbar.pack_end (hash_waiting);

            app_notification = new Granite.Widgets.Toast ("");
            var overlay = new Gtk.Overlay ();
            overlay.add (content);
            overlay.add_overlay (app_notification);

            desktop_notification = new Notification (_ ("Finished"));

            build_image_area ();

            build_device_area ();

            build_flash_area ();

            this.add (overlay);
            this.show_all ();
        }

        private void build_image_area () {
            image_container = new Gtk.Grid ();
            image_container.row_spacing = 24;
            image_container.width_request = 180;

            var title = new Gtk.Label (_ ("Image"));
            title.get_style_context ().add_class ("h2");
            title.hexpand = true;
            image_container.attach (title, 0, 0, 1, 1);

            var image_logo = new Gtk.Image.from_icon_name ("folder-open", Gtk.IconSize.DIALOG);
            image_container.attach (image_logo, 0, 1, 1, 1);

            open_image = new Gtk.Button.with_label (_ ("Select Image"));
            open_image.clicked.connect (select_image);
            image_container.attach (open_image, 0, 3, 1, 1);

            image_name = new Gtk.Label ("");
            image_name.max_width_chars = 30;
            image_name.use_markup = true;
            image_name.wrap = true;
            set_image_label ("");
            image_container.attach (image_name, 0, 2, 1, 1);

            content.attach (image_container, 0, 0, 1, 1);
        }

        private void build_device_area () {
            device_container = new Gtk.Grid ();
            device_container.sensitive = false;
            device_container.row_spacing = 24;
            device_container.width_request = 180;

            var title = new Gtk.Label (_ ("Device"));
            title.get_style_context ().add_class ("h2");
            title.hexpand = true;
            device_container.attach (title, 0, 0, 1, 1);

            var device_grid = new Gtk.Grid ();
            device_list = new Gtk.FlowBox ();
            device_list.child_activated.connect (select_drive);

            device_grid.add (device_list);

            device_logo = new Gtk.Image.from_icon_name ("drive-removable-media-usb", Gtk.IconSize.DIALOG);
            device_container.attach (device_logo, 0, 1, 1, 1);

            select_device = new Gtk.Button.with_label (_ ("Select Drive"));
            select_device.valign = Gtk.Align.END;
            select_device.vexpand = true;
            select_device.clicked.connect (
                () => {
                    device_popover.visible = !device_popover.visible;
                });
            device_container.attach (select_device, 0, 3, 1, 1);

            device_name = new Gtk.Label (("<i>%s</i>").printf (_ ("No removable devices found…")));
            device_name.use_markup = true;
            device_container.attach (device_name, 0, 2, 1, 1);

            device_popover = new Gtk.Popover (select_device);
            device_popover.position = Gtk.PositionType.TOP;
            device_popover.add (device_grid);

            device_popover.show.connect (
                () => {
                    if (selected_device != null) {
                        device_list.select_child (selected_device);
                    }
                    select_device.grab_focus ();
                });

            device_grid.show_all ();
            content.attach (device_container, 1, 0, 1, 1);
        }

        private void build_flash_area () {
            flash_container = new Gtk.Grid ();
            flash_container.row_spacing = 24;
            flash_container.sensitive = false;
            flash_container.width_request = 180;

            burning = new Gtk.Spinner ();
            burning.active = false;

            var title = new Gtk.Label (_ ("Flash"));
            title.get_style_context ().add_class ("h2");
            title.hexpand = true;
            flash_container.attach (title, 0, 0);

            start_logo = new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.DIALOG);

            flash_container.attach (burning, 0, 1);
            flash_container.attach (start_logo, 0, 1);

            flash_start = new Gtk.Button.with_label (_ ("Write Image"));
            flash_start.valign = Gtk.Align.END;
            flash_start.vexpand = true;
            flash_start.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            flash_start.clicked.connect (flash_image);
            flash_container.attach (flash_start, 0, 3);

            flash_label = new Gtk.Label ("");
            flash_label.use_markup = true;
            set_flash_label ();
            flash_container.attach (flash_label, 0, 2);

            content.attach (flash_container, 2, 0);
        }

        private void select_image () {
            var file = new Gtk.FileChooserDialog (
                _ ("Open"), this,
                Gtk.FileChooserAction.OPEN,
                _ ("_Cancel"), Gtk.ResponseType.CANCEL,
                _ ("_Open"), Gtk.ResponseType.ACCEPT);

            var image_filter = new Gtk.FileFilter ();
            image_filter.set_filter_name (_ ("Image files"));
            image_filter.add_mime_type ("application/x-raw-disk-image");

            file.add_filter (image_filter);

            if (file.run () == Gtk.ResponseType.ACCEPT) {
                selected_image = file.get_file ();
                debug (file.get_filename ());
                get_checksum.begin ();
            }

            file.destroy ();
        }

        private void select_drive (Gtk.FlowBoxChild item) {
                debug ("Selected: %s", (item as Imageburner.Device).drive.get_name ());
            this.selected_device = item as Imageburner.Device;
        }

        private void flash_image () {
            if (!burner.is_running) {
                selected_device.umount_all_volumes ();
                burner.flash_image (selected_image, selected_device.drive);
            }
        }

        private void device_added (GLib.Drive drive) {
            foreach (var child in this.device_list.get_children ()) {
                if ((child as Device).unix_device == drive.get_identifier ("unix-device")) {
                    return;
                }
            }

            var item = new Imageburner.Device (drive);
            this.selected_device = item;
            this.device_list.add (item);
            this.device_list.show_all ();

            this.device_container.sensitive = selected_image != null && has_removable_devices;
        }

        private void device_removed (GLib.Drive drive) {
                debug ("Remove device from list");
            foreach (var child in this.device_list.get_children ()) {
                if ((child as Device).drive == drive) {
                    child.destroy ();
                }
            }
            if (selected_device != null && selected_device.drive == drive) {
                if (this.has_removable_devices) {
                    selected_device = this.device_list.get_children ().last ().data as Device;
                } else {
                    selected_device = null;
                }
            }

            this.device_container.sensitive = selected_image != null && has_removable_devices;
        }

        private void set_image_label (string text) {
            if (text != "") {
                this.image_name.label = text;
            } else {
                this.image_name.label = ("<i>%s</i>").printf (_ ("Choose an image file…"));
            }
        }

        private void set_device_label (string text) {
            if (text != "") {
                this.device_name.label = text;
            } else {
                this.device_name.label = ("<i>%s</i>").printf (_ ("No removable devices found…"));
            }
        }

        private void set_flash_label () {
            if (selected_image == null) {
                this.flash_label.label = ("<i>%s</i>").printf (_ ("No image file chosen…"));
            } else if (selected_device == null) {
                this.flash_label.label = ("<i>%s</i>").printf (_ ("No device chosen…"));
            } else {
                this.flash_label.label = _ ("Ready!");
            }
        }

        public async void get_checksum () {
            calculate_begin ();
            checksum_thread.begin (
                (obj, res) => {
                    calculate_finished (checksum_thread.end (res));
                });
        }

        private async string checksum_thread () {
            SourceFunc callback = checksum_thread.callback;
            ChecksumType checksumtype = ChecksumType.SHA256;
            switch (hash_chooser.active_id) {
            case "MD5" :
                checksumtype = ChecksumType.MD5;
                break;
            case "SHA1" :
                checksumtype = ChecksumType.SHA1;
                break;
            }
            string digest = "";

            ThreadFunc<void*> run = () => {
                Checksum checksum = new Checksum (checksumtype);
                FileStream stream = FileStream.open (selected_image.get_path (), "r");
                uint8 fbuf[100];
                size_t size;

                while ((size = stream.read (fbuf)) > 0) {
                    checksum.update (fbuf, size);
                }
                digest = checksum.get_string ();
                Idle.add ((owned) callback);
                return null;
            };
            try {
                new Thread<void*>.try (null, run);
            } catch (Error e) {
                warning (e.message);
            }

            yield;
            return digest;
        }
    }
}
