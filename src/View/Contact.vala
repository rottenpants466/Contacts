/*
* Copyright (c) {{yearrange}} Alex ()
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alex Angelou <>
*/

using Granite;
using Granite.Widgets;
using Gtk;

using View.Widgets;
using ViewModel;
using DataHelper;

public errordomain FileChooserError {
    USER_CANCELED
}

namespace View {

    public class Contact : Granite.SettingsPage {

        public ContactHandler handler = new ContactHandler ();

        public signal void delete ();
        public signal void name_changed ();
        public signal void changed ();
        private signal void has_icon (bool has);

        private Granite.Widgets.Avatar icon = new Granite.Widgets.Avatar.from_file ("../data/icons/64/contacts-avatar-default.svg", 64);
        private bool icon_is_set = false;

        private EditableTitle name_label = new EditableTitle ("");

        private InfoSection phone_info = new InfoSection ("Phones");
        private InfoSection email_info = new InfoSection ("Emails");
        private InfoSectionSegmented address_info = new InfoSectionSegmented ("Addresses", {
            "Street",
            "City",
            "State/Province",
            "Zip/Postal Code",
            "Country"
        });
        private InfoSectionMisc misc_info = new InfoSectionMisc ("Miscellaneous");

        public string contact_name {
            get {
                return title;
            }
            set {
                title = value;
                name_label.text = value;
                changed ();
            }
        }

        public Contact (string name = "") {

            Object (
                display_widget: new Granite.Widgets.Avatar.from_file ("../data/icons/32/contacts-avatar-default.svg", 32),
                //header: name[0].to_string (),
                title: name
            );
            this.name = name.replace(" ", "_") + "_contact";
            contact_name = name;
        }

        construct {
            var icon_button = new Gtk.Button ();
            icon_button.get_style_context ().add_class ("flat");
            icon_button.add (icon);

            var popup = new IconPopup (icon_button);
            has_icon.connect ((has) => {
                popup.can_delete = has;
                icon_is_set = has;
            });

            popup.change_image.connect (() => {
                try {
                    get_icon_from_file ();
                } catch {
                    print ("You canceled the operation\n");
                }
            });

            set_connections ();

            var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            title_box.pack_start (icon_button, false, false, 0);
            title_box.pack_start (name_label, false, false, 0);

            var flow_box = new Gtk.FlowBox ();
            flow_box.set_homogeneous (false);
            flow_box.set_orientation (Gtk.Orientation.HORIZONTAL);
            flow_box.add (phone_info);
            flow_box.add (email_info);
            flow_box.add (address_info);
            flow_box.add (misc_info);
            flow_box.set_selection_mode (Gtk.SelectionMode.NONE);
            flow_box.set_activate_on_single_click (false);

            var delete_button = new Gtk.Button ();
            delete_button.set_label ("Delete Contact");
            delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            delete_button.clicked.connect (() => delete_contact());

            var save_button = new Gtk.Button ();
            save_button.set_label ("Save");
            save_button.clicked.connect (() => handler.save());

            var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bottom_box.pack_end (save_button, false, false, 0);
            bottom_box.pack_end (delete_button, false, false, 0);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
            content_area.margin = 12;
            content_area.pack_start (title_box, false, false, 0);
            content_area.pack_start (flow_box, false, false, 0);
            content_area.pack_end (bottom_box, false, false, 0);
            content_area.pack_end (separator, false, false, 0);
            this.add (content_area);

            handler.name = name;
        }

        private void delete_contact () {
            this.delete ();
            this.destroy ();
        }

        private void get_icon_from_file () throws FileChooserError {
            var chooser = new Gtk.FileChooserNative (
                "Choose an image",                      // name: string
                (Gtk.Window) this.get_toplevel (),      // transient parent: Gtk.Window
                FileChooserAction.OPEN,                 // File chooser action: FileChooserAction
                null,                                   // Accept label: string
                null                                    // Cancel label: string
            );

            var filter = new Gtk.FileFilter ();
            filter.set_name ("Image");
            filter.add_mime_type ("image/*");

            chooser.add_filter (filter);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                name = chooser.get_filename ();
            } else {
                throw new FileChooserError.USER_CANCELED ("User canceled file choosing");
            }

            chooser.destroy ();
            set_image_path (name);
            changed ();
        }

        public void set_image_path (string path) {
            try {
                handler.icon =  new Gdk.Pixbuf.from_file_at_scale (path, 64, 64, true);
                icon.pixbuf = handler.icon;
                ((Granite.Widgets.Avatar) display_widget).pixbuf = handler.icon.scale_simple (32, 32, Gdk.InterpType.HYPER);;
                has_icon (true);
            } catch (Error e) {
                stderr.printf (e.message);
            }
        }

        private void set_connections () {
            name_label.changed.connect (() => {
                title = name_label.text;
                handler.name = name_label.text;
                name_changed ();
                changed ();
            });

            phone_info.handler.add = handler.add_phone;
            phone_info.handler.remove = (index) => {
                handler.remove_phone (index);
                if (index == 0) status = "";
            };
            phone_info.handler.change = (phone, type, index) => {
                if (index == 0) status = phone;
                return handler.set_phone (phone, type, index);
            };

            email_info.handler.add = handler.add_email;
            email_info.handler.remove = handler.remove_email;
            email_info.handler.change = handler.set_email;

            address_info.handler.add = handler.add_address;
            address_info.handler.remove = handler.remove_address;
            address_info.handler.change = handler.set_address;

            misc_info.handler.add_note = handler.add_note;
            misc_info.handler.remove_note = handler.remove_note;
            misc_info.handler.change_note = handler.set_note;

            misc_info.handler.add_website = handler.add_website;
            misc_info.handler.remove_website = handler.remove_website;
            misc_info.handler.change_website = handler.set_website;

            misc_info.handler.add_nickname = handler.add_nickname;
            misc_info.handler.remove_nickname = handler.remove_nickname;
            misc_info.handler.change_nickname = handler.set_nickname;

            misc_info.handler.set_birthday = (day, month, year) => handler.birthday.set_dmy (day, month, year);
            misc_info.handler.new_birthday = () => handler.birthday = Date ();
            misc_info.handler.clear_birthday = () => handler.birthday = null;
        }
    }
}