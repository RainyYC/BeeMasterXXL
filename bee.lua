local component = require("component")
--local serialization = require("serialization")

local strategy, mutations, device, speciesLookup

local function initialize()
    if not component.inventory_controller then
        error("缺少物品栏交互升级")
    elseif not component.robot then
        error("此程序需要在机器人上运行")
    elseif component.robot.inventorySize() < 32 then
        error("需要2个物品栏升级")
    elseif not component.crafting then
        error("缺少合成升级")
    elseif not component.beekeeper then
        error("缺少养蜂员升级")
    elseif not component.database then
        error("缺少数据库升级")
    elseif not component.upgrade_me then
        error("缺少ME升级")
    elseif not component.upgrade_me.isLinked() then
        error("未连接到ME网络")
    elseif component.inventory_controller.getInventoryName(0) ~= "tile.oc.charger" then
        error("机器人初始位置应位于OC充电器上方")
    end
    print("加载中...")
    mutations = require("mutations")
    device = require("device")
    strategy = require("strategy")
    speciesLookup = require("speciesLookup")
    speciesLookup.initialize(mutations)
end

local function handleSingleMatch(result)
    print(string.format("找到品种: %s [%s]", result.name, result.id))
    strategy.task(result.id)
end

local function handleMultipleMatches(result)
    print(string.format("找到 %d 个匹配的品种:", #result.matches))
    for i, m in ipairs(result.matches) do
        print(string.format("  [%d] %s [%s]", i, m.name, m.id))
    end
    while true do
        print("请输入序号选择目标品种（输入 0 重新搜索）:")
        local choice = tonumber(io.read())
        if choice and choice == 0 then
            return false
        elseif choice and choice >= 1 and choice <= #result.matches then
            local species = result.matches[choice].id
            strategy.task(species)
            return true
        else
            print("无效的选择，请重新输入")
        end
    end
end

local function main()
    while true do
        print("请输入需要培育的蜜蜂（支持中文名或品种ID）:")
        local input = io.read()
        local result = speciesLookup.find(input)
        if not result then
            print("未找到匹配的蜜蜂品种，请重新输入")
        elseif result.single then
            handleSingleMatch(result)
            break
        elseif result.multiple then
            local done = handleMultipleMatches(result)
            if done then
                break
            end
        end
    end
end

local suc, err = pcall(initialize)
if suc then
    suc, err = pcall(main)
    if not suc then
        print("发生错误: " .. err)
        device.destruct()
    end
else
    print("发生错误: " .. err)
end
