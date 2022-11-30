--------------------------------------------------------
-- Erases pixels found in padding of tileset
--
-- Developed by Mpdacey 2022
--------------------------------------------------------

-- Erases padding within given tileset.
-- Parameters:
-- - base:    The base image to be erased from.
-- - tile:    The measurements of the tiles.
-- - padding: The space between tiles that will be erased.
-- - pc:      The pixel color used to compare pixels
function ErasePadding(base, tile, padding, pc)
    -- Erases the columns in padding
    for c = tile.x, base.width, tile.x+padding.x do
        for y = 0, base.height, 1 do
            for x = 0, padding.x-1, 1 do
                base:drawPixel(x+c,y,pc.rgba(0,0,0,0))
            end
        end
    end

    -- Erases the rows in padding, will not repeating
    -- what was already erased in the previous segment.
    for c = 0, base.width, tile.x+padding.x do
        for r = tile.y, base.height, tile.y+padding.y do
            for y = 0, padding.y-1, 1 do
                for x = 0, tile.x-1, 1 do
                    base:drawPixel(x+c,y+r,pc.rgba(0,0,0,0))
                end
            end
        end
    end
    
    return base
end

local cel = app.activeCel
if not cel then
    return app.alert("There is no active image.")
end

local base = cel.image:clone()
local pc = app.pixelColor
local tile = {};
local padding = {};

-- Dialog window for inputting variables
local dlg = Dialog("Padding Eraser")
    dlg:number{ id="tileX", label="Tile Width & Height (px):", text="16", decimals=integer}
    dlg:number{ id="tileY", text="16", decimals=integer}
    dlg:newrow()
    dlg:number{ id="paddingX", label="Spacing Width & Height (px):", text="4", decimals=integer}
    dlg:number{ id="paddingY", text="4", decimals=integer}
    dlg:button{ id="confirm", text="Confirm" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

local data = dlg.data
if data.confirm then
    tile.x = data.tileX
    tile.y = data.tileY
    padding.x = data.paddingX
    padding.y = data.paddingY

    -- Save erasure to allow undoable action.
    cel.image = ErasePadding(base, tile, padding, pc)

    -- Redraw pixels in app
    app.refresh()
end