local debug = {}

debug.doPrint = false

function debug.print(value)
    if debug.doPrint then print(value) end
end

return debug
