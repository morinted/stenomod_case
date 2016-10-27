include <boxes.scad>

// Units in mm

x = 0;
y = 1;
z = 2;
LEFT = 0;
RIGHT = 1;

// Stenomod PCB is only this big... and not very thick.
pcb = [124.5, 80, 1.6];

// The radius of each corner, needs to allow lip to fit.
// This library seems to have issues when you go below 5.
// Experiment with values +-3.6 and you'll see what I mean.
corner_radius = 2.5;

top_space = 6;
top_thickness = 1.5;
top_height = top_thickness + top_space;

// Trade off between size and time.
wall_thickness = 2.5;

/**
 * LIP is a joining between the top and bottom of case.
 * Top lip goes *over* bottom lip, should prevent
 * unsightly grooves and moisture spilling into the case
 * with gravity.
 */
// The lip is half and half of the wall.
lip_thickness = wall_thickness / 2;
// How far up the lip reaches
lip_height = 2;
// Spacing between lips.
lip_tolerance = 0.25;

// Bottom layer thickness
base_thickness = 1.5;
// To allow for solder joins and the like.
bottom_space = 4;
base_height = base_thickness + bottom_space + pcb[z];

case = [pcb[0] + wall_thickness*2, pcb[1] + wall_thickness*2, base_height];

// Around screwholes and in center
support_size = 5;

// Cut outs for the keys
top_paths = [
    [
        // Something like this shapewise.
        // xxxxxxxxxx
        // x1    2xxx
        // x     3 4x
        // xA   9 65x
        // xxxxx8 7xx
        [pcb[x] - 29, 4],
        [20, 4],
        [20, 0.5],
        [9, 0.5],
        [9, 23],
        [2.5, 23],
        [2.5, pcb[y] - 21],
        [12, pcb[y] - 21],
        [12, pcb[y] - 2.5],
        [48, pcb[y] - 2.5],
        [48, pcb[y] - 21],
        [pcb[x] - 29, pcb[y] - 21],
    ],
    [
        [pcb[x] - 2.5, pcb[y] - 21],
        [pcb[x] - 2.5, 23],
        [pcb[x] - 9, 23],
        [pcb[x] - 9, 0.5],
        [pcb[x] - 20, 0.5],
        [pcb[x] - 20, 4],
        [29, 4],
        [29, 22],
        [10, 22],
        [10, pcb[y] - 21],
        [76, pcb[y] - 21],
        [76, pcb[y] - 2.5],
        [pcb[x] - 12.5, pcb[y] - 2.5],
        [pcb[x] - 12.5, pcb[y] - 21],
    ],
];

// Cutout for the USB on the left.
// The jack on the teensy is the largest part, so I don't cover it.
// Might be unsightly?
usb_hole = [13, 7 + wall_thickness, 20];
usb_location = [
    pcb[x] - 12 - pcb[x]/2,
    1 - pcb[y]/2,
    0
];

// Screw holes for each hand.
screw_holes = [
    [
        [pcb[x] - 24, 5], // top left
        [5, 5], // top right
        [pcb[x] - 10.25, pcb[y] - 5], // bottom left
        [5, pcb[y] - 5], // bottom right
    ],
    [
        [pcb[x] - 5, 5], // TL
        [10, 5], // TR
        [pcb[x] - 5, pcb[y] - 5], // BL
        [10, pcb[y] - 5], // BR  
    ]
];

// Supports the PCB in the middle.
mid_support = [pcb[x]/2 - 65, 40 - pcb[y]/2];

// We want to get over the the teensy, and up to the bottom of the key.
// These happen to be about the same height. Strategy: start thinner around the teensy,
// skip the USB port as it's tall.
key_base = 6;

// Cuts holes like the ones in the PCB through entire model
module draw_screw_holes(side) {
    for (screw = screw_holes[side]) {
       translate([screw[x] - pcb[x]/2, screw[y] - pcb[y]/2, base_thickness + bottom_space/2]) {
           cylinder(h=40, d=3.5, center=true, $fn=10);
       }
    }
}

// Lip to offer connection between top and base.
module lip(offset) {
    difference() {
            cube([pcb[x] + lip_thickness*2 + offset, pcb[y] + lip_thickness*2 + offset, lip_height], true);
            cube([pcb[x], pcb[y], lip_height], true);
    }
}

// Stenomod logo for use (can't think of where to fit it)
module logo(height) {
    rotate([0, 180, 0]) {
        linear_extrude(height = height, center = true, convexity = 10) {
            scale([0.03, 0.03]) {
                import("stenomod-traced.dxf", convexity=10);
            }
        }
    }
}

// Base of case (bottom half)
module base(side) {
    difference() {
        translate([0, 0, base_height / 2]) {
            roundedBox([case[0], case[1], base_height], corner_radius, true);
        }
        translate([0, 0, base_thickness + base_height/2]) {
            cube([pcb[x], pcb[y], base_height], true);
        }
    }
    // supports
    for (screw = screw_holes[side]) {
       translate([screw[x] - pcb[x]/2, screw[y] - pcb[y]/2, base_thickness + bottom_space/2]) {
           cube([support_size, support_size, bottom_space], true);
       }
    }
    translate([mid_support[x], mid_support[y], base_thickness + bottom_space/2]) {
       cube([support_size, support_size, bottom_space], true);
    }
    
    // lip on top of wall
    translate([0, 0, base_height + lip_height/2]) {
        lip(-lip_tolerance/2);
    }
}

// Top of case (top half, facing down, must be flipped to print)
module top(side) {
    difference() {
        translate([0, 0, top_height / 2]) {
            roundedBox([case[0], case[1], top_height], corner_radius, true);
        }
        translate([0, 0, (top_height - top_thickness)/2 - 0.01]) {
            cube([pcb[x], pcb[y], top_space], true);
        }
        translate([0, 0, lip_height/2]) {
            lip(lip_tolerance/2);
        }
                translate(-[pcb[x]/2, pcb[y]/2, -top_space + 0.01]) {
            linear_extrude(height = top_thickness + 0.02) {
                polygon(points=top_paths[side]);
            }
        }
        if (side == LEFT) {
            translate(usb_location) {
                cube(usb_hole, true);
            }
        }
        // Logo won't print upside down :(
        //translate([11, 30, top_height]) {
        //    logo(top_thickness/2);
        //}
    }

    // supports
    for (screw = screw_holes[side]) {
       translate([screw[x] - pcb[x]/2, screw[y] - pcb[y]/2, top_space/2]) {
           cube([support_size, support_size, top_space], true);
       }
    }
}

module both(side) {
    base(side);
    translate([0, 0, base_height + 0.2]) {
        top(side);
    }     
}


// Change these to render different parts
LEFT_BASE = 0; // Can be printed as-is
LEFT_TOP = 1; // Must be printed upside down!
RIGHT_BASE = 2; // as-is
RIGHT_TOP = 3; // upside down
// Previews
// Note: uncomment cross-section box to see inside the walls.
CASE_L = 4; // Preview left hand, with spacer to show split
CASE_R = 5; // Preview right hand
module draw() {
  part = CASE_L;
  if (part == LEFT_BASE) {
    difference() {
        base(LEFT);
        draw_screw_holes(LEFT);
    }
  } else if (part == LEFT_TOP) {
    difference() {
        top(LEFT);
        draw_screw_holes(LEFT);
    }
  } else if (part == RIGHT_BASE) {
    difference() {
        base(RIGHT);
        draw_screw_holes(RIGHT);
    }
  } else if (part == RIGHT_TOP) {
    difference() {
        top(RIGHT);
        draw_screw_holes(RIGHT);
    }
  } else if (part == CASE_L) {
    difference() {
        both(LEFT);
        draw_screw_holes(LEFT);
        // cross section
        cube([100, 100, 100]);
    }
  } else if (part == CASE_R) {
    difference() {
        both(RIGHT);
        draw_screw_holes(RIGHT);
        // cross section
        cube([100, 100, 100]);
    } 
  }
}
draw();
