--------------------------------------------------------
-- Bleeds pixels of current cel into transparent padding cels
--
-- Developed by Mpdacey 2022
--------------------------------------------------------

-- Bleeds the pixels of a given base image so that they seep into the 
-- padding without effecting the tile.
-- Parameters:
-- - base:    The base image that will be used to gauge where bleed pixels should go.
-- - tile:    The measurements of the tiles.
-- - padding: The space between tiles that will be bled into.
-- - depth:   The amount of space allowed to be bled into.
-- - pc:      The pixel color used to compare pixels
function PerformBleed(base, tile, padding, depth, pc)
    local bleed = base:clone()
    local source = {}
    local distance = {}
    local relative = {}

    -- Iterates through each pixel in base
    for y = 0, base.height, 1 do
        for x = 0, base.width, 1 do
            -- If pixel isn't transparent, skip
            if pc.rgbaA(base:getPixel(x,y)) == 0 then
                -- Get relative position of current tile
                relative.x = x%(tile.x+padding.x)-tile.x
                relative.y = y%(tile.y+padding.y)-tile.y

                -- Check if relative position is within padding
                if relative.x >= 0 or relative.y >= 0 then

                    -- If X position is within padding, than calculate distance from nearest pixel on X axis.
                    if relative.x >= 0 then
                        if relative.x >= padding.x / 2 then
                            distance.x = padding.x - relative.x
                        else
                            distance.x = -relative.x - 1;
                        end
                    else
                        distance.x = 0
                    end

                    -- If Y position is within padding, than calculate distance from nearest pixel on Y axis.
                    if relative.y >= 0 then
                        if relative.y >= padding.y / 2 then
                            distance.y = padding.y - relative.y
                        else
                            distance.y = -relative.y - 1;
                        end
                    else
                        distance.y = 0
                    end

                    -- Check if distance is within specified depth
                    if distance.x <= depth and distance.x >= -depth and distance.y <= depth and distance.y >= -depth then
                        -- Find source pixel to draw colour from
                        source.x = x + distance.x
                        source.y = y + distance.y

                        -- If source is within bounds of image, then bleed pixel into current
                        if source.x >= 0 and source.x < base.width and source.y >= 0 and source.y < base.height then
                            bleed:drawPixel(x, y, base:getPixel(source.x,source.y))
                        end
                    end
                end
            end
        end
    end

    return bleed;
end

-- Bleeds the pixels of a given base image so that all pixels bleed into neighbouring transparent space.
-- This method could be used for non-uniform sprites, but the results could be unsatisfactory.
-- Parameters:
-- - base:    The base image that will be used to gauge where bleed pixels should go.
-- - pc:      The pixel color used to compare pixels
function PerformUnprotectedBleed(base, pc)
    local bleed = base:clone()

    -- Iterates through each pixel in base
    for y = 0, base.height, 1 do
        for x = 0, base.width, 1 do
            if pc.rgbaA(base:getPixel(x,y)) == 0 then
                if y < base.height-1 and pc.rgbaA(base:getPixel(x,y+1)) ~= 0 then
                    bleed:drawPixel(x,y,base:getPixel(x,y+1))
                elseif x > 0 and pc.rgbaA(base:getPixel(x-1,y)) ~= 0 then
                    bleed:drawPixel(x,y,base:getPixel(x-1,y))
                elseif x < base.width-1 and pc.rgbaA(base:getPixel(x+1,y)) ~= 0 then
                    bleed:drawPixel(x,y,base:getPixel(x+1,y))
                elseif y > 0 and pc.rgbaA(base:getPixel(x,y-1)) ~= 0 then
                    bleed:drawPixel(x,y,base:getPixel(x,y-1))
                end
            end
        end
    end

    return bleed
end

local cel = app.activeCel
if not cel then
    return app.alert("There is no active image.")
end

local base = cel.image:clone()
local pc = app.pixelColor
local tile = {};
local padding = {};
local depth = 1
local protection = true

-- Dialog window for inputting variables
local dlg = Dialog("Tile Bleeder")
    dlg:number{ id="tileX", label="Tile Width & Height (px):", text="16", decimals=integer}
    dlg:number{ id="tileY", text="16", decimals=integer}
    dlg:newrow()
    dlg:number{ id="paddingX", label="Spacing Width & Height (px):", text="4", decimals=integer}
    dlg:number{ id="paddingY", text="4", decimals=integer}
    dlg:newrow()
    dlg:number{ id="depth", label="Bleeding Depth (px):", text="2", decimals=integer}
    dlg:newrow()
    dlg:check{ id="protection", label="Protect Tile Internals:", selected=true, onclick= 
        function ()
            if dlg.data.protection then
                dlg:modify{id="depth", label="Bleeding Depth:"}
            else
                dlg:modify{id="depth", label="Bleed Repetitions:"}
            end

            dlg:modify{id="tileX", enabled = dlg.data.protection}
            dlg:modify{id="tileY", enabled = dlg.data.protection}
            dlg:modify{id="paddingX", enabled = dlg.data.protection}
            dlg:modify{id="paddingY", enabled = dlg.data.protection}
            dlg:modify{ id="warning", visible = not dlg.data.protection }
        end
    }
    dlg:separator{ id="warning", text="WARNING: Unprotected bleeds are slow. Results maybe unsatisfactory." }
    dlg:modify{ id="warning", visible=false }
    dlg:button{ id="confirm", text="Confirm" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

local data = dlg.data
if data.confirm then
    tile.x = data.tileX
    tile.y = data.tileY
    padding.x = data.paddingX
    padding.y = data.paddingY
    depth = data.depth
    protection = data.protection

    if protection then
        base = PerformBleed(base, tile, padding, depth, pc)
    else
        local space = {}
        space.x = (tile.x + padding.x)/2
        space.y = (tile.y + padding.y)/2

        -- If depth is greater than half of any tile + padding, then reduce it, as it is redundant to iterate any further
        if depth > space.x and depth > space.y then
            if space.x > space.y then
                depth = space.x
            else
                depth = space.y
            end
        end

        for iterations = 1, depth, 1 do
            base = PerformUnprotectedBleed(base, pc)
        end
    end

    -- Save bleed to allow undoable action.
    cel.image = base

    -- Redraw pixels in app
    app.refresh()
end