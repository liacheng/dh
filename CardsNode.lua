--
-- Author: zhong
-- Date: 2016-06-27 09:42:21
--
local CardSprite = require("game.yule.baccaratnew.src.views.layer.gamecard.CardSprite")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

local BJL_CARD_X_POS = 110;
local ANI_BEGIN = 0.1;
local function ANI_RATE( var )
	return var * ANI_BEGIN;
end
local CARD_SHOW_SCALE = 0.7;

local CardsNode = class("CardsNode", cc.Node)

function CardsNode:ctor()
end

function CardsNode:createEmptyCardsNode( ... )
	local node = CardsNode.new();
	if nil ~= node and node:init() then
		node.m_mapCard = {};
		node.m_vecCard = {};
		node.m_cardsData = {}
		node:addCardsHolder();

		return node;
	end
	return nil;
end

--更新扑克卡牌
function CardsNode:updateCardsNode( cards, isShowCard, bAnimation, pCallBack,reconnection)
	if 0 == cards.m_cardCount then
		print("count = 0");
		return;
	end
	local m_cardsData = cards;
	local m_cardCount = #cards;

	self.m_bAddCards = false;
	self.m_bDispatching = true;

	self:removeAllCards();
	self.m_cardsData = m_cardsData;
	self.m_cardsCount = m_cardCount;
	self.m_bShowCard = isShowCard;

	--转换为相对于自己的中间位置
	local winSize = cc.Director:getInstance():getWinSize();
	local centerPos = cc.p(winSize.width * 0.5, winSize.height * 0.5);
	centerPos = self:convertToNodeSpace(centerPos);

	local mapKey = 0;
	local m_cardsHolder = self.m_cardsHolder;
	--创建扑克
	for i=1,m_cardCount do
		local tmpSp = CardSprite:createCard(m_cardsData[i])
		tmpSp:setPosition(centerPos);
		tmpSp:setDispatched(false);
		tmpSp:showCardBack(true);
		--tmpSp:setScale(0.6);
		m_cardsHolder:addChild(tmpSp);
		if 0 == m_cardsData[i] then
			mapKey = i;
		else
			mapKey = m_cardsData[i];
		end
		self.m_mapCard[mapKey] = tmpSp;
		table.insert(self.m_vecCard, tmpSp);
	end

	self:arrangeAllCards(bAnimation, pCallBack,reconnection);
end

function CardsNode:addCards(cbCard, pCallBack,reconnection)
	local len = #self.m_cardsData
	local total = len + 1
	if total > 3 then 
		return
	end
	self.m_bAddCards = false
	--百家乐，顶部位置
	local winSize = cc.Director:getInstance():getWinSize()
	local centerPos = cc.p(660, 700)
	centerPos = self:convertToNodeSpace(centerPos)

	local tmpSp = CardSprite:createCard(cbCard)
	if tmpSp == nil then return end
	self.m_cardsData[total] = cbCard
	self.m_mapCard[cbCard] = tmpSp
	table.insert(self.m_vecCard, tmpSp)
	tmpSp:setVisible(false)
	tmpSp:setDispatched(false)
	tmpSp:showCardBack(true)
	tmpSp:setPosition(centerPos)
	self.m_cardsHolder:addChild(tmpSp)
	self.m_cardsCount = total
	self:arrangeAllCards(true, pCallBack,reconnection)
end

function CardsNode:getHandCards(  )
	return self.m_cardsData
end

--
function CardsNode:addCardsHolder(  )
	if nil == self.m_cardsHolder then
		self.m_cardsHolder = cc.Node:create();
		self:addChild(self.m_cardsHolder);
	end
end

function CardsNode:removeAllCards()
	self.m_mapCard = {}
	self.m_vecCard = {}
	if nil ~= self.m_cardsHolder then
		self.m_cardsHolder:removeAllChildren();
	end
	self.m_cardsData = {}
end
--牌回收
function CardsNode:removeCards(leftOrRight,reconnection)
    if self.m_cardsCount ~= nil then
        local count = self.m_cardsCount;
        if count > 0 then
           for i=1,count do
           	if reconnection == false then
                ExternalFun.playSoundEffect("SEND_CARD.mp3")
            end
			    local tmp = self.m_vecCard[i];
			    tmp:stopAllActions()
			    --坐标转换
			    local winSize = cc.Director:getInstance():getWinSize();
			    local centerPos = cc.p(660 + appdf.g_GameOffX, 700)
			    centerPos = self:convertToNodeSpace(centerPos);
                local time = 0.5;
                if leftOrRight == kLEFT_ROLE then
                   time = 0.8;
                end
                local moveTo = cc.MoveTo:create(time,centerPos);
                local rotBy = cc.RotateBy:create(time, 360*2)
                local fadeTo = cc.FadeTo:create(0.001, 0)
                local spawn = cc.Spawn:create(moveTo,rotBy);
                tmp:runAction(cc.Sequence:create(moveTo,fadeTo));
                tmp:setVisible(true)
		    end
        end	
    end
end
--小李子  这个函数是扑克的显示
function CardsNode:arrangeAllCards( showAnimation, pCallBack , reconnection)
	local idx = 0;
	if showAnimation then
		local count = self.m_cardsCount;
		local center = count * 0.5;
		if 1 == count then
			center = 1;
		elseif 2 == count then
			center = 1.5;
		elseif 3 == count then
			center = 2;
		end
	--	print("count ------------------",count)
		for i=1,count do
			local tmp = self.m_vecCard[i];
			tmp:stopAllActions()
			local pos = cc.p((i - center) * BJL_CARD_X_POS, 0)
			dump(pos)
			print("pos ------------------",pos)
			--小李子  这个函数是扑克的位置修改
			if tmp:getDispatched() then
				--tmp:setPosition(pos)
			else
				tmp:setDispatched(true)
				tmp:setVisible(true)

				--坐标转换
				local winSize = cc.Director:getInstance():getWinSize();
				local centerPos = cc.p(winSize.width * 0.5, winSize.height * 0.5);
				centerPos = self:convertToNodeSpace(centerPos);
				--local moveTo = cc.MoveTo:create(ANI_BEGIN * 0.5, cc.p(centerPos.x, 0));
				--小李子  你的那个不需要移动所以注释了
				--local moveTo2 = cc.MoveTo:create(0.1, pos);
				tmp:setPosition(pos)
				local delay = cc.DelayTime:create(ANI_BEGIN);
				local hideBack = cc.CallFunc:create(function ( )
					if false == self.m_bAddCards then
						--播放音乐
						if reconnection == false then
							ExternalFun.playSoundEffect("SEND_CARD.mp3")
						end
					end
				end)
				local seq = cc.Sequence:create(delay, hideBack);
                local scaleToAni = cc.ScaleTo:create(0.1,0.7)
				local spawn = cc.Spawn:create(scaleToAni,cc.CallFunc:create(function()
						if i == count and nil ~= pCallBack then
							tmp:runAction(pCallBack)
							pCallBack:release()

							self.m_bDispatching = false
						end
					end), seq)
                tmp:setOpacity(0)
                tmp:setVisible(true)
                tmp:showCardBack(false)
                tmp:runAction(cc.FadeTo:create(0.04, 255))
                tmp:setScale(0.1);
                --local moveToAni = cc.MoveTo:create(0.33, cardpoint[i]);
                
                --local spawnAni = cc.Spawn:create(moveToAni,scaleToAni);
                --card:runAction(cc.Sequence:create(spawnAni,cc.MoveBy:create(0.04*(j-1), cc.p(32*(j-1),0))))
				--[[local runSeq = cc.Sequence:create(cc.DelayTime:create(ANI_RATE(idx)), spawn, cc.DelayTime:create(0.05), moveTo2,cc.CallFunc:create(function() 
						tmp:showCardBack(false)
					end))]]
                local runSeq = cc.Sequence:create(cc.DelayTime:create(0.3 * idx + idx * 0.2 ), spawn, cc.CallFunc:create(function() 
					tmp:showCardBack(false)
				end))
				tmp:runAction(runSeq)
				idx = idx + 1
			end
		end
	else
		--整理卡牌位置
		--self:reSortCards();
	end
end

function CardsNode:reSortCards(  )
	local count = self.m_cardsCount;

	for i=1,count do
		local cbCardData = self.m_cardsData[i];
		local tmpSp = self.m_mapCard[cbCardData];
		if nil == tmpSp then
			local sp = CardSprite:createCard(cbCardData);
			sp:showCardBack(true);
			sp:setLocalZOrder(i);
			self.m_cardsHolder:addChild(sp);
			self.m_mapCard[cbCardData] = sp;
			table.insert(self.m_vecCard, sp);
		end
	end

	--针对百家乐的最多三张
    local center = count * 0.5;
    if ( 1 == count) then
        center = 1;
    elseif ( 2 == count) then
        center = 1.5;
    elseif (3 == count) then
        center = 2.0;
    end
    
    for i=1,count do
    	local cardData = self.m_cardsData[i];
    	
    	if nil ~= self.m_mapCard[cardData] then
    		local tmpSp = self.m_vecCard[i];
    		
    		tmpSp:setScale(CARD_SHOW_SCALE);
    		tmpSp:stopAllActions();
    		tmpSp:setDispatched(true);
    		tmpSp:showCardBack(false);
    		local pos = cc.p((i - center) * BJL_CARD_X_POS, 0);
    		tmpSp:setPosition(pos);

    		if i == count then
    			self.m_bDispatching = false;
    		end
    	end
    end
end

return CardsNode;