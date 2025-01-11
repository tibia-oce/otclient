local lootWindow = nil
local categoriesIds = {
	[LOOT_CATEGORY_GOLD] = {'Coins', 15},
	[LOOT_CATEGORY_VALUABLES] = {'Valuables', 16},
	[LOOT_CATEGORY_EQUIPMENT] = {'Equipment', 5},
	[LOOT_CATEGORY_POTIONS] = {'Potions', 27},
	[LOOT_CATEGORY_AMMUNITION] = {'Ammunition', 11},
	[LOOT_CATEGORY_CREATURE_PRODUCTS] = {'Creature Products', 7},
	[LOOT_CATEGORY_FOOD] = {'Food', 23},
	[LOOT_CATEGORY_SPECIAL] = {'Special', 59},
	[LOOT_CATEGORY_MISC] = {'Misc', 35}
}

function init()
    g_ui.importStyle('containers')

    connect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem,
        onUpdate = onContainersUpdate
    })
    connect(Game, {
        onGameEnd = clean()
    })

    reloadContainers()
end

function terminate()
    g_logger.warning("Terminating module...")
    disconnect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem,
        onUpdate = onContainersUpdate
    })
    disconnect(Game, {
        onGameEnd = clean()
    })
end

function reloadContainers()
    clean()
    for _, container in pairs(g_game.getContainers()) do
        onContainerOpen(container)
    end
end

function clean()
    destroyLoot()
    for containerid, container in pairs(g_game.getContainers()) do
        destroy(container)
    end
end

function destroy(container)
    if container.window then
        container.window:destroy()
        container.window = nil
        container.itemsPanel = nil
    end
end

function refreshContainerItems(container)
  g_logger.error("FrefreshContainerItems " .. container)
  for slot=0,container:getCapacity()-1 do
    local itemWidget = g_ui.createWidget('ContainerItem', containerPanel)
    local item = container:getItem(slot)
    itemWidget:setItem(item)
    ItemsDatabase.setRarityItem(itemWidget, item)
    ItemsDatabase.setTier(itemWidget, item)

    local categoryIdWidget = itemWidget:getChildById('lootCategoryId')
    if not categoryIdWidget then
        g_logger.error("Failed to find 'lootCategoryId' for item at slot " .. slot)
    else
        categoryIdWidget:hide()
    end

    if item then
      local iconId = getIconId(item:getLootCategory())
      if iconId ~= LOOT_CATEGORY_NONE then
        categoryIdWidget:show()
        setIconImageType(categoryIdWidget, iconId)
      end
    end
  end

  if container:hasPages() then
    refreshContainerPages(container)
  end
end

function toggleContainerPages(containerWindow, pages)
    containerWindow:getChildById('miniwindowScrollBar'):setMarginTop(pages and 42 or 22)
    containerWindow:getChildById('contentsPanel'):setMarginTop(pages and 42 or 22)
    containerWindow:getChildById('pagePanel'):setVisible(pages)
end

function refreshContainerPages(container)
    local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
    local pages = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
    container.window:recursiveGetChildById('pageLabel'):setText(string.format('Page %i of %i', currentPage, pages))

    local prevPageButton = container.window:recursiveGetChildById('prevPageButton')
    if currentPage == 1 then
        prevPageButton:setEnabled(false)
    else
        prevPageButton:setEnabled(true)
        prevPageButton.onClick = function()
            g_game.seekInContainer(container:getId(), container:getFirstIndex() - container:getCapacity())
        end
    end

    local nextPageButton = container.window:recursiveGetChildById('nextPageButton')
    if currentPage >= pages then
        nextPageButton:setEnabled(false)
    else
        nextPageButton:setEnabled(true)
        nextPageButton.onClick = function()
            g_game.seekInContainer(container:getId(), container:getFirstIndex() + container:getCapacity())
        end
    end
end

function onContainerOpen(container, previousContainer)
    -- todo(autoloot)
    g_logger.warning("Opening container with ID: " .. container:getId())
    g_logger.warning("Container Name: " .. container:getName())
    g_logger.warning("Capacity: " .. container:getCapacity())
    g_logger.warning("Items Count: " .. container:getItemsCount())

    local containerWindow
    if previousContainer then
        containerWindow = previousContainer.window
        previousContainer.window = nil
        previousContainer.itemsPanel = nil
    else
        containerWindow = g_ui.createWidget('ContainerWindow')
    end
    containerWindow:setId('container' .. container:getId())
    local containerPanel = containerWindow:getChildById('contentsPanel')
    local containerItemWidget = containerWindow:getChildById('containerItemWidget')
    containerWindow.onClose = function()
        g_game.close(container)
        containerWindow:hide()
    end

    -- this disables scrollbar auto hiding
    local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
    scrollbar:mergeStyle({
        ['$!on'] = {}
    })

    local upButton = containerWindow:getChildById('upButton')
    upButton.onClick = function()
        g_logger.warning("Navigating to parent container...")
        g_game.openParent(container)
    end
    upButton:setVisible(container:hasParent())

    local name = container:getName()
    name = name:sub(1, 1):upper() .. name:sub(2)

    if name:len() > 11 then
        name = string.sub(name, 1, #name - 3)
        name = name .. "..."
    end

    containerWindow:setText(name)

    containerItemWidget:setItem(container:getContainerItem())
    containerItemWidget:setPhantom(true)

    containerPanel:destroyChildren()
    for slot = 0, container:getCapacity() - 1 do
        g_logger.warning("Processing slot: " .. slot)
        local itemWidget = g_ui.createWidget('ContainerItem', containerPanel)
        local item = container:getItem(slot)
        itemWidget:setId('item' .. slot)
        itemWidget:setItem(item)
        itemWidget:setMargin(0)
        itemWidget.position = container:getSlotPosition(slot)
        
        if item then
            g_logger.warning("Item ID: " .. item:getId())
            g_logger.warning("Item Category: " .. item:getLootCategory())
        else
            g_logger.warning("Slot " .. slot .. " is empty.")
        end

        if not itemWidget then
            g_logger.error("Failed to create item widget at slot " .. slot)
        end

        local categoryIdWidget = itemWidget:getChildById('lootCategoryId')
        categoryIdWidget:hide()
        if item then
          local iconId = getIconId(item:getLootCategory())
          if iconId ~= LOOT_CATEGORY_NONE then
            categoryIdWidget:show()
            setIconImageType(categoryIdWidget, iconId)
          end
        end

        if not container:isUnlocked() then
            itemWidget:setBorderColor('red')
        end
    end

    container.window = containerWindow
    container.itemsPanel = containerPanel

    toggleContainerPages(containerWindow, container:hasPages())
    refreshContainerPages(container)

    local layout = containerPanel:getLayout()
    local cellSize = layout:getCellSize()
    containerWindow:setContentMinimumHeight(cellSize.height)
    containerWindow:setContentMaximumHeight(cellSize.height * layout:getNumLines() + 15)

    if not previousContainer then
        local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)
        panel:addChild(containerWindow)

        if modules.client_options.getOption('openMaximized') then
            containerWindow:setContentHeight(cellSize.height * layout:getNumLines())
        else
            local filledLines = math.max(math.ceil(container:getItemsCount() / layout:getNumColumns()), 1)
            containerWindow:setContentHeight(filledLines * cellSize.height)
        end
    end

    containerWindow:setup()
end

function onContainerClose(container)
    destroy(container)
end

function onContainerChangeSize(container, size)
    if not container.window then
        return
    end
    g_logger.warning("Refreshing container items...")
    refreshContainerItems(container)
end

function onContainerUpdateItem(container, slot, item, oldItem)
  if not container.window then return end
  local itemWidget = container.itemsPanel:getChildById('item' .. slot)
  itemWidget:setItem(item)

  local categoryIdWidget = itemWidget:getChildById('lootCategoryId')
  categoryIdWidget:hide()
  if item then
    local iconId = getIconId(item:getLootCategory())
    if iconId ~= LOOT_CATEGORY_NONE then
      categoryIdWidget:show()
      setIconImageType(categoryIdWidget, iconId)
    end
  end
end

function onContainersUpdate(container)
	if not container.window then return end
    g_logger.warning("Refreshing container items...")
	refreshContainerItems(container)
end


function destroyLoot()
	if lootWindow then
		lootWindow:destroy()
		lootWindow = nil
		categoriesList = nil
		currentSelect = nil
		acceptButton = nil
	end
end

function addLootCategory()
	if not lootWindow then
		return false
	end

	if not currentSelect or currentSelect == 0 then
		return false
	end

	g_game.addLootCategory(lootWindow.item, currentSelect)
	destroyLoot()
end

function onRemoveLootCategory(item)
	g_game.removeLootCategory(item)
end

function getIconId(flags)
	local iconId = LOOT_CATEGORY_NONE
	for k, v in pairs(categoriesIds) do
		local bitValue = 2 ^ k
		if g_game.bitoper(flags, bitValue, AND) then
			if iconId ~= LOOT_CATEGORY_NONE then
				return 52
			end

			iconId = v[2]
		end
	end

	return iconId
end

function getCategoryIcon(flags)
	local description = ""
	for k, v in pairs(categoriesIds) do
		local bitValue = 2 ^ k
		if g_game.bitoper(flags, bitValue, AND) then
			if description ~= "" then
				description = description .. ", "
			end

			description = description .. v[1]
		end
	end

	return description
end

function selectCategoryId(self, mousePosition, mouseButton)
	if not lootWindow then
		return false
	end

	if not currentSelect then
		currentSelect = 0
	end

	local bitValue = 2 ^ tonumber(self:getId())
	if g_game.bitoper(currentSelect, bitValue, AND) then
		currentSelect = currentSelect - bitValue
		self:setChecked(false)
	else
		currentSelect = currentSelect + bitValue
		self:setChecked(true)
	end

	acceptButton:setEnabled(currentSelect ~= 0)
end

function getImageClip(id)
	return (((id - 1) % 8) * 19) .. ' ' .. ((math.ceil(id / 8) - 1) * 19) .. ' ' .. 19 .. ' ' .. 19
end

function setIconImageType(widget, id)
	widget:setImageClip(getImageClip(id))
end

function onLootCategory(item)
	if not lootWindow then
		lootWindow = g_ui.displayUI('container_loot_category')
		lootWindow.item = item
		categoriesList = lootWindow:getChildById('categoriesList')
		acceptButton = lootWindow:getChildById('button')

		local categoryFlags = item:getLootCategory()
    for i = LOOT_CATEGORY_FIRST, LOOT_CATEGORY_LAST do
			local widget = g_ui.createWidget('LootCategory', categoriesList)
			widget:setText(categoriesIds[i][1])
			widget:setId(i)
			setIconImageType(widget:getChildById('categoryIcon'), categoriesIds[i][2])
			widget.onMouseRelease = selectCategoryId

			local bitValue = 2 ^ i
			if g_game.bitoper(categoryFlags, bitValue, AND) then
				selectCategoryId(widget)
			end
		end
	end
end
