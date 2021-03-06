require_relative 'LeadscrewNutBlock'
require_relative 'ZMotorAssembly'

PLATFORM_BRACKET_THICKNESS = ACRYLIC_THICKNESS
PLATFORM_BRACKET_SPACING = Z_RAIL_SPACING + LeadscrewNutBlock.height + PLATFORM_BRACKET_THICKNESS

extrusion :ZCarriagePanel do
    attr_reader height: 4.cm
    attr_reader width: PLATFORM_BRACKET_SPACING + ACRYLIC_THICKNESS

    length ACRYLIC_THICKNESS

    repeat_count = 3
    attr_reader slot_count: (repeat_count + 1)/2
    attr_reader slot_length: height/repeat_count
    attr_reader slot_spacing: 2*height/repeat_count

    polygon do
        start_at    [-width/2, -height/2]

        i = 0
        repeat to:[last.x, last.y + height], count:repeat_count do |step|
            right length if i.odd?
            forward step
            i = i + 1
        end

        right       width

        i = 0
        repeat to:[last.x, last.y - height], count:repeat_count do |step|
            right length if i.odd?
            forward step
            i = i + 1
        end
    end

    # Pas-thrus for the leadscrews
    repeat step:[Z_RAIL_SPACING, 0], count:[2,1] do
        circle diameter:10.5.mm
    end
end

extrusion :PlatformBracketBoxPanel do
    attr_reader height: 5.5.cm
    attr_reader width: PLATFORM_BRACKET_SPACING + ACRYLIC_THICKNESS
    attr_reader repeat_count: 5
    attr_reader slot_count: (repeat_count + 1)/2
    attr_reader slot_length: height/repeat_count

    length ACRYLIC_THICKNESS

    polygon do
        start_at    [-width/2, -height/2]

        i = 0
        repeat to:[last.x, last.y + height], count:repeat_count do |step|
            right length if i.odd?
            forward step
            i = i+1
        end

        right       width

        i = 0
        repeat to:[last.x, last.y - height], count:repeat_count do |step|
            right length if i.odd?
            forward step
            i = i+1
        end
    end
end

extrusion :PistonBoxBottomPanel do
    length ACRYLIC_THICKNESS

    attr_reader height: Z_RAIL_SPACING_Y + 4.cm
    attr_reader width: PLATFORM_BRACKET_SPACING + length

    attr_reader repeat_count: 10
    attr_reader slot_count: (repeat_count + 1)/2
    attr_reader slot_length: height/repeat_count

    polygon do
        start_at    [-width/2, -height/2]

        i = 0
        repeat to:[last.x, last.y + height], count:repeat_count do |step|
            right length if i.even?
            forward step
            i = i+1
        end

        right       width

        i = 0
        repeat to:[last.x, last.y - height], count:repeat_count do |step|
            right length if i.odd?
            forward step
            i = i+1
        end
    end

    # Pas-throughs for the leadscrews
    repeat step:[Z_RAIL_SPACING, Z_RAIL_SPACING_Y], count:[2, 2] do
        circle diameter:10.5.mm
    end
end

extrusion :PlatformBracket do
    attr_reader thickness: PLATFORM_BRACKET_THICKNESS
    attr_reader flange_height: 3.6.cm
    attr_reader platform_width: PLATFORM_SIZE.y
    attr_reader slot_height: 0
    attr_reader flange_length: ZCarriagePanel.height.mm
    attr_reader rail_spacing: Z_RAIL_SPACING_Y

    attr_reader width: PistonBoxBottomPanel.height

    min_height = BUILD_VOLUME.z + flange_height
    if (ZMotorAssembly.sprocket_top + TopRetainer.thickness) > BUILD_VOLUME.z
        min_height += ZMotorAssembly.sprocket_top.cm + TopRetainer.thickness - BUILD_VOLUME.z.cm
    end
    attr_reader height: min_height

    attr_reader carriage_panel_offsets: repeat(center:[platform_width/2, LeadscrewNutBlock.length + 1.5*ZCarriagePanel.length - height], step:rail_spacing, count:[2,1])
    attr_reader box_panel_offsets: repeat(center:[platform_width/2, 4.25.cm - height], spacing:[8.52.cm, 2.2.cm], count:[2, 1])
    attr_reader slot_width: (width - 2*flange_length - platform_width)/2

    platform_inset = 1.mm
    platform_tab_length = 3.cm

    length thickness
    polygon origin:[platform_inset, 0] do
        right       (platform_width - platform_tab_length)/2 - platform_inset.cm
        move_y      ACRYLIC_THICKNESS
        move_x      platform_tab_length
        move_y      -ACRYLIC_THICKNESS
        right_to    platform_width - 2*platform_inset

        down        height - flange_height
        right       platform_inset
        right       slot_width
        up          slot_height
        right       flange_length
        down        slot_height
        down        flange_height

        i = 0
        repeat step:[-PistonBoxBottomPanel.slot_length, 0], count:PistonBoxBottomPanel.repeat_count do |step|
            right PistonBoxBottomPanel.length if i.even?
            forward step
            i = i + 1
        end

        left_to     -platform_inset - slot_width - flange_length

        up          flange_height
        up          slot_height

        right       flange_length
        down        slot_height
        right       slot_width + platform_inset
    end

    # Slots for the carriage panel
    carriage_panel_offsets.each do |offset|
        repeat center:offset, step:[ZCarriagePanel.slot_spacing, 0], count:[ZCarriagePanel.slot_count,1] do
            rectangle center:[0, 0], size:[-ZCarriagePanel.slot_length, ZCarriagePanel.length]
        end
    end

    translate 0, -height do     # Start at the bottom
        platform_center_x = platform_width/2

        # Slots for box panels
        repeat center:[platform_center_x, 4.25.cm], spacing:[8.52.cm, 2.2.cm], count:[2, PlatformBracketBoxPanel.slot_count] do
            rectangle center:[0,0], size:[PlatformBracketBoxPanel.length, PlatformBracketBoxPanel.slot_length]
        end

        # Clearance holes for the leadscrew nut block bolts
        repeat center:[platform_center_x, PistonBoxBottomPanel.length + LeadscrewNutBlock.length/2], step:rail_spacing, count:[2,1] do
            LeadscrewNutBlock.bolt_holes.each {|center| circle center:center, diameter:LeadscrewNutBlock.bolt_hole_diameter }
        end
    end
end

extrusion :PlatformPanel do
    attr_reader size: PLATFORM_SIZE.inset(0.1.mm)
    attr_reader thickness: ACRYLIC_THICKNESS

    length thickness
    rectangle center:[0,0], size:size
    repeat step:PLATFORM_BRACKET_SPACING, count:2 do
        rectangle center:[0,0], size:[PlatformBracket.thickness, 3.cm]
    end
end

model :PistonAssembly do
    attr_reader bracket_spacing: PLATFORM_BRACKET_SPACING
    attr_reader bracket_width: bracket_spacing + PlatformBracket.thickness
    attr_reader flange_height: PlatformBracket.flange_height
    attr_reader rail_spacing: Size[Z_RAIL_SPACING, PLATFORM_SIZE.y + 7.cm]

    attr_reader height: PlatformBracket.height

    translate z:-PlatformPanel.thickness do
        push PlatformPanel

        translate y:-PlatformPanel.size.y/2 do
            # Brackets
            [-bracket_spacing/2, bracket_spacing/2].each do |x|
                push PlatformBracket, origin: [x - PlatformBracket.length/2, 0, 0], x:Y, y:Z
            end

            PlatformBracket.carriage_panel_offsets.each do |offset|
                push ZCarriagePanel, origin:[0, offset.x, offset.y - ZCarriagePanel.length/2]
            end

            PlatformBracket.box_panel_offsets.each do |origin|
                push PlatformBracketBoxPanel, origin:[0, origin.x + PlatformBracketBoxPanel.length/2, origin.y], x:X, y:Z
            end
        end

        push PistonBoxBottomPanel, origin:[0, 0, -PlatformBracket.height]
    end

    translate z:-PlatformBracket.height - 0.8.mm do
        [-rail_spacing.y/2, rail_spacing.y/2].each do |y|
            [-rail_spacing.x/2, rail_spacing.x/2].each do |x|
                push LeadscrewNutBlock, origin:[x, y, 0.8.mm], x:Y, y:-X
            end
        end
    end
end
