local M = {}

local mutations

local nameToIds = {}
local idToName = {}
local idToAlias = {}

function M.initialize(mutationsTable)
    mutations = mutationsTable
    for id, data in pairs(mutations) do
        local entry = data
        if type(data) == "table" and data[1] then
            entry = data[1]
        end

        local name = entry.name
        if name then
            if not nameToIds[name] then
                nameToIds[name] = {}
            end
            table.insert(nameToIds[name], id)
            idToName[id] = name

            local alias = entry.alias
            if alias and alias ~= name then
                idToAlias[id] = alias
                if not nameToIds[alias] then
                    nameToIds[alias] = {}
                end
                table.insert(nameToIds[alias], id)
            end
        end
    end
end

local function labelFor(id)
    local name = idToName[id] or id
    local alias = idToAlias[id]
    if alias then
        return name .. "（又称" .. alias .. "）"
    end
    return name
end

local function entriesForIds(ids)
    local result = {}
    local seen = {}
    for _, id in ipairs(ids) do
        if not seen[id] then
            seen[id] = true
            table.insert(result, { name = labelFor(id), id = id })
        end
    end
    return result
end

local function makeResult(entries)
    if #entries == 0 then
        return nil
    elseif #entries == 1 then
        return { single = true, id = entries[1].id, name = entries[1].name }
    else
        return { multiple = true, matches = entries }
    end
end

function M.find(input)
    if not mutations then
        error("speciesLookup 尚未初始化，请先调用 initialize()")
    end

    input = input:gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then
        return nil
    end

    local matchedIds = {}

    if mutations[input] then
        table.insert(matchedIds, input)
    end

    if nameToIds[input] then
        for _, id in ipairs(nameToIds[input]) do
            table.insert(matchedIds, id)
        end
    end

    for name, ids in pairs(nameToIds) do
        if name:find(input, 1, true) then
            for _, id in ipairs(ids) do
                table.insert(matchedIds, id)
            end
        end
    end

    for id, _ in pairs(mutations) do
        if id:find(input, 1, true) then
            table.insert(matchedIds, id)
        end
    end

    return makeResult(entriesForIds(matchedIds))
end

return M
