// SPDX-License-Identifier: CC0-1.0
//
// zmk-create-skeleton.v
//
// Creates skeleton files for the ZMK template (https://github.com/zmkfirmware/unified-zmk-config-template)
//
// ./boards/shields/KBD_NAME/
//     Kconfig.shield
//     Kconfig.defconfig
//     KBD_NAME.overlay
//     KBD_NAME.keymap
//     KBD_NAME.zmk.yml
//
// Installation:
//   1. Install V. Refer to https://github.com/vlang/v/blob/master/README.md#installing-v-from-source.
//   2. Compile: e.g., `v zmk-create-skeleton.v`
//   3. Move the executable to a directory in your PATH: e.g., `mv zmk-create-skeleton ~/.local/bin`
//
// Usage:
//   1. Navigate to the template folder you just cloned: e.g., `cd ~/foo-zmk-config`
//   2. Run this program without any arguments: e.g., `zmk-create-skeleton`
//   3. You can Build your new keyboard at this time:
//      ```
//      cd ~/foo-zmk-config
//      west build -s ~/zmk/app -p -b seeeduino_xiao_rp2040 -- -DSHIELD=foo -DZMK_CONFIG=$PWD/config
//      ```
//   4. Additionally, you can use `rg TODO:` to find hints on where modifications should be made in the source.

import os

fn exit_if(cond bool, msg string, retval int) {
    if cond {
        println(msg)
        exit(retval)
    }
}

pgm_name := os.args[0]
help_msg := 'Usage: ${pgm_name}

Creates skeleton files for ZMK as follows:
    ./boards/shields/KBD_NAME/
        Kconfig.shield
        Kconfig.defconfig
        KBD_NAME.overlay
        KBD_NAME.keymap
        KBD_NAME.zmk.yml
'

// entry -------------------------------------------------------------------
mut kbd_name := ''
dir_name := os.base(os.getwd())

if os.args.len == 1 {
    if dir_name == dir_name.split('-')[0] + '-zmk-config' {
        kbd_name = dir_name.split('-')[0]
    }
    else if dir_name == 'zmk-config-' + dir_name.rsplit('-')[0] {
        kbd_name = dir_name.rsplit('-')[0]
    }
    else {
        kbd_name = dir_name
    }
}
else {
    println(help_msg)
    exit(0)
}

base_dir := './boards/shields'

exit_if(!os.is_dir(base_dir), '  Error: Not found sub-folder "${base_dir}", quit.', -1)

kbd_name_l := kbd_name.to_upper()
kbd_dir := os.join_path_single(base_dir, kbd_name)

if os.is_dir(kbd_dir) {
    println('  ${kbd_dir}: folder already exists.')
    ans := os.input('  Do you want to create only the missing files instead of quit? (y/N) ')
    if ans != r'y' {
        println('  quit.')
        exit(0)
    }
    println('')
}
else {
    println('  ${kbd_dir}: folder create')
    os.mkdir(kbd_dir, os.MkdirParams{})!
}

templates := {
    'Kconfig.shield':'config SHIELD_${kbd_name_l}
  def_bool $(shields_list_contains,${kbd_name})
'

    'Kconfig.defconfig':'if SHIELD_${kbd_name_l}
  config ZMK_KEYBOARD_NAME
    default "${kbd_name} TODO: change as you like"
endif
'

    '.overlay':'/ {
    chosen {
        zmk,kscan = &kscan0;
    };

    kscan0: kscan_0 {
        compatible = "zmk,kscan-gpio-direct";
        input-gpios
            = <&xiao_d 0 (GPIO_ACTIVE_LOW | GPIO_PULL_UP)>
            // ^^^^^^^^^ TODO: depends on using mcu
            ;
    };
};

// TODO: add wheels and/or pointing devices
'

    '.keymap':'#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>
/ {
    keymap {
        compatible = "zmk,keymap";
        default_layer {
// -------------
// | a |            // TODO: add keys
            bindings = <
&kp A               // TODO: add keys
            >;
        };
    };
};
'
    '.zmk.yml':'file_format: "1"
id: 1key
name: 1key keyboard
type: shield
url: https://github.com/TODO: USER_NAME/${dir_name}
requires: [seeed_xiao]  # TODO: as you like
features:
  - keys
  # TODO: add some features
'
}

// create skeleton files if it does not exist, otherwise skip it
for k,v in templates {
    file_name := if k[0] == `.` { kbd_name + k } else { k }
    path := os.join_path_single(kbd_dir, file_name)
    if os.is_file(path) {
        eprintln('  ${path}: file already exists, skip')
    }
    else {
        println('  ${path}: create')
        os.write_file(path, v)!
    }
}

// print result
cmd := 'ls -l ${kbd_dir}'
println('')
println(cmd)
os.system(cmd)

