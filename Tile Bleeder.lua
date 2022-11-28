--------------------------------------------------------
-- Bleeds pixels of current cel into transparent cels
--
-- Developed by Mpdacey 2022
--------------------------------------------------------

-- Bleeds the pixels of a given base image so that they seep into the 
-- padding without effecting the tile.
-- Parameters:
-- - base:    The base image that will be used to gauge where bleed pixels should go.
-- - tile:    The measurements of the tiles.
-- - padding: The space between tiles that will be bled into.
-- - pc:      The pixel color used to compare pixels
function PerformBleed(base, tile, padding, protection, pc)
    local bleed = base:clone()

    -- Iterates through each pixel in base
    for y = 0, base.height, 1 do
        for x = 0, base.width, 1 do
            -- Account for padding
            if not protection or x%(tile.x+padding.x)-tile.x >= 0 or y%(tile.y+padding.y)-tile.y >= 0 then
                -- If the current pixel is transparent, then check all neighbouring pixels
                -- If a neighbouring pixel isnt transparent, then adopt its pixel and draw it on bleed
                -- Checks in this order: Below, Left, Right, Above
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
    end

    return bleed;
end

local cel = app.activeCel
if not cel then
    return app.alert("There is no active image.")
end

local base = cel.image:clone()
local pc = app.pixelColor
local tile = {};
local padding = {};
local iterations = 1
local protection = true

-- Dialog window for inputting variables
local dlg = Dialog("Tile Bleeder")
    dlg:number{ id="tileX", label="Tile Width & Height (px):", text="16", decimals=integer}
    dlg:number{ id="tileY", text="16", decimals=integer}
    dlg:newrow()
    dlg:number{ id="paddingX", label="Spacing Width & Height:", text="4", decimals=integer}
    dlg:number{ id="paddingY", text="4", decimals=integer}
    dlg:newrow()
    dlg:number{ id="iterations", label="Bleeding Repetitions:", text="2", decimals=integer}
    dlg:newrow()
    dlg:check{ id="protection", label="Protect Tile Internals:", selected=true}
    dlg:button{ id="confirm", text="Confirm" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

local data = dlg.data
if data.confirm then
    tile.x = data.tileX
    tile.y = data.tileY
    padding.x = data.paddingX
    padding.y = data.paddingY
    iterations = data.iterations
    protection = data.protection

    -- If iterations is greater than any padding, then reduce it, as it is redundant to iterate further
    if iterations > padding.x and iterations > padding.y then
        if padding.x > padding.y then
            iterations = padding.x
        else
            iterations = padding.y
        end
    end

    for i = 1, iterations, 1 do
        base = PerformBleed(base, tile, padding, protection, pc)
    end

    -- Save bleed to allow undoable action.
    cel.image = base

    -- Redraw pixels in app
    app.refresh()
end