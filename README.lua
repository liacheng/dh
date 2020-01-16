--
-- Author: zhong
-- Date: 2016-07-15 11:03:17
--
--游戏扑克层
local GameCardLayer = class("GameCardLayer", cc.Layer)

local module_pre = "game.yule.baccaratnew.src"
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var;
local CardsNode = module_pre .. ".views.layer.gamecard.CardsNode"
local GameLogic = module_pre .. ".models.GameLogic"
local cmd = module_pre .. ".models.CMD_Game"
local bjlDefine = module_pre .. ".models.bjlGameDefine"

local scheduler = cc.Director:getInstance():getScheduler()

local kPointDefault = 0
local kDraw = 1 --平局
local kIdleWin = 2 --闲赢
local kMasterWin = 3 --庄赢
local DIS_SPEED = 0.5
local DELAY_TIME = 1.0
local kLEFT_ROLE = 1
local kRIGHT_ROLE = 2

function GameCardLayer:ctor(parent)
	self.m_parent = parent
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/GameCardLayer.csb",self)	
	self.m_actionNode = csbNode
	csbNode:setVisible(false)
	self.m_action = nil

	--点数
	self.m_tabPoint = {}
	self.m_tabPoint[kLEFT_ROLE] = csbNode:getChildByName("idle_res_sp")
	self.m_tabPoint[kRIGHT_ROLE] = csbNode:getChildByName("master_res_sp")
	--扑克
	self.m_tabCards = {}	
	local idle = g_var(CardsNode):createEmptyCardsNode()
	idle:setPosition(330, 780)
	
	csbNode:addChild(idle)
	self.m_tabCards[kLEFT_ROLE] = idle

	local master = g_var(CardsNode):createEmptyCardsNode()
	master:setPosition(1010, 780)
	
	csbNode:addChild(master)
	self.m_tabCards[kRIGHT_ROLE] = master	

	self.m_vecDispatchCards = {}
	self.m_nTotalCount = 0
	self.m_scheduler = nil
	self.m_nDispatchedCount = 0
	self.m_bAnimation = false

	self:reSet()
end

function GameCardLayer:clean(  )
	if nil ~= self.m_action then
		self.m_action:release()
		self.m_action = nil
	end

	if nil ~= self.m_scheduler then
		scheduler:unscheduleScriptEntry(self.m_scheduler)
		self.m_scheduler = nil
	end

	self.m_actionNode:stopAllActions()
end

function GameCardLayer:showLayer( var )
	self.m_actionNode:setVisible(var)
	self:setVisible(var)
	if false == var then
		self.m_actionNode:stopAllActions()
		if nil ~= self.m_scheduler then
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
		end
	end
end
function GameCardLayer:removeAllCards()
    self.m_tabCards[kRIGHT_ROLE]:removeCards(kRIGHT_ROLE)
    self.m_tabCards[kLEFT_ROLE]:removeCards(kLEFT_ROLE)
end
function GameCardLayer:refresh( tabRes, bAni, cbTime )
	self:reSet()

	local m_nTotalCount = #tabRes.m_idleCards + #tabRes.m_masterCards
	self.m_nTotalCount = m_nTotalCount


	local masterIdx = 1
	local idleIdx = 1
	local loopCount = m_nTotalCount - 1
	for i = 0, loopCount do
		local dis = g_var(bjlDefine).getEmptyDispatchCard()		
		if 0 ~= bit:_and(i,1) then
			if nil ~= tabRes.m_masterCards[masterIdx] then
				dis.m_dir = kRIGHT_ROLE
				dis.m_cbCardData = tabRes.m_masterCards[masterIdx]
				masterIdx = masterIdx + 1
			else
				dis.m_dir = kLEFT_ROLE
				dis.m_cbCardData = tabRes.m_idleCards[idleIdx]
				idleIdx = idleIdx + 1
			end
		else
			if nil ~= tabRes.m_idleCards[idleIdx] then
				dis.m_dir = kLEFT_ROLE
				dis.m_cbCardData = tabRes.m_idleCards[idleIdx]
				idleIdx = idleIdx + 1
			else
				dis.m_dir = kRIGHT_ROLE
				dis.m_cbCardData = tabRes.m_masterCards[masterIdx]
				masterIdx = masterIdx + 1
			end
		end	
		table.insert(self.m_vecDispatchCards, dis)
	end	
	
	self.m_bAnimation = bAni
	if bAni then
		self:switchLayout(false)
		if nil == self.m_action then 
			self:initAni()
		end
        self:onAnimationEnd()
	else
		self:switchLayout(true)

		--刷新点数
		self.m_tabCards[kLEFT_ROLE]:updateCardsNode(tabRes.m_idleCards, true, false)
		self.m_tabCards[kLEFT_ROLE]:setScale(0.75)
		self:refreshPoint(kLEFT_ROLE)
		
		self.m_tabCards[kRIGHT_ROLE]:updateCardsNode(tabRes.m_masterCards, true, false)
		self.m_tabCards[kRIGHT_ROLE]:setScale(0.75)
		self:refreshPoint(kRIGHT_ROLE)

		self:calResult()
	end	
end

function GameCardLayer:initAni(  )
	local act = ExternalFun.loadTimeLine("game/GameCardLayer.csb")
	self.m_action = act
	self.m_action:retain()
	local function onFrameEvent( frame )
		if nil == frame then
            return
        end        

        local str = frame:getEvent()
        if str == "end_fun" 
        and true == self.m_bAnimation
        and true == self:isVisible() then

        	self.m_actionNode:stopAllActions()
        	self:onAnimationEnd()
        elseif str == "end_draw" then
        	self:switchLayout(true)
            
        end
        
	end
	act:setFrameEventCallFunc(onFrameEvent)
end

function GameCardLayer:reSet()
	self.m_vecDispatchCards = {}

	self.m_tabCards[kLEFT_ROLE]:removeAllCards()
	self.m_tabCards[kRIGHT_ROLE]:removeAllCards()
    
	self.m_tabCards[kLEFT_ROLE]:setScale(0.75)
	self.m_tabCards[kRIGHT_ROLE]:setScale(0.75)


    self.m_tabPoint[kLEFT_ROLE]:setString("0")
	self.m_tabPoint[kRIGHT_ROLE]:setString("0")

	self.m_nTotalCount = 0
	self.m_nDispatchedCount = 0
	self.m_enPointResult = kPointDefault

end

function GameCardLayer:onAnimationEnd( )
    
	--定时器发牌
	local function countDown(dt)
		self:dispatchUpdate()
	end
	if nil == self.m_scheduler then
		self.m_scheduler = scheduler:scheduleScriptFunc(countDown, DIS_SPEED, false)
	end
end

function GameCardLayer:dispatchUpdate( )
	if 0 ~= #self.m_vecDispatchCards then
		self.m_nDispatchedCount = self.m_nDispatchedCount + 1
		local dis = self.m_vecDispatchCards[1]
		table.remove(self.m_vecDispatchCards, 1)

		local cbCard = dis.m_cbCardData
		local function callFun( sender, tab )
			self:refreshPoint(tab[1])
		end
		self:addCards(cbCard, dis.m_dir, cc.CallFunc:create(callFun,{dis.m_dir}))

        if self.m_nDispatchedCount < 4 then
           self.m_nDispatchedCount = self.m_nDispatchedCount + 1
		   local dis = self.m_vecDispatchCards[1]
		   table.remove(self.m_vecDispatchCards, 1)
		   local cbCard = dis.m_cbCardData
		   local function callFun( sender, tab )
			self:refreshPoint(tab[1])
		   end
		   self:addCards(cbCard, dis.m_dir, cc.CallFunc:create(callFun,{dis.m_dir}))
        end

		self:noticeTips()
	else
		self:calResult()
		if nil ~= self.m_scheduler then
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
		end	
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
                    function ()
                         if nil ~= self.m_parent then
			                self.m_parent:showBetAreaBlink()
		                end
                    end
                )))
		
	end
end

function GameCardLayer:calResult( )
	--不做排序，按顺序计算
	local idleCards = self.m_tabCards[kLEFT_ROLE]:getHandCards()
	--g_var(GameLogic).SortCardList(idleCards, GameLogic.ST_ORDER)
	local idlePoint = g_var(GameLogic).GetCardListPip(idleCards)
	local masterCards = self.m_tabCards[kRIGHT_ROLE]:getHandCards()
	--g_var(GameLogic).SortCardList(masterCards, GameLogic.ST_ORDER)
	local masterPoint = g_var(GameLogic).GetCardListPip(masterCards)
    local idleTime = 1;
    local callback1 = cc.CallFunc:create(
                    function ()
                          ExternalFun.playSoundEffect("xianjia.mp3")
                    end
                )
    local callback2 = cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("tianpai.mp3")
                    end
                )
    local callback3 = cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("dian_"..idlePoint..".mp3")
                    end
                )
    local callback4 = cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("zuanjia.mp3")
                    end
                )
    local callback5 = cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("dian_"..masterPoint..".mp3")
                    end
                )
    if idlePoint == 8 or  idlePoint == 9 then
        self:runAction(cc.Sequence:create(callback1,cc.DelayTime:create(0.5),callback2,cc.DelayTime:create(0.8),callback3 ))
        idleTime = 2;
    else
        idleTime = 1;
        self:runAction(cc.Sequence:create(callback1,cc.DelayTime:create(0.5),callback3 ))
    end
    --self:runAction(cc.Sequence:create(callback1,cc.DelayTime:create(0.5),callback3 ))
    if masterPoint == 8 or  masterPoint == 9 then
       self:runAction(cc.Sequence:create(cc.DelayTime:create(idleTime),callback4 ,cc.DelayTime:create(0.5),callback2,cc.DelayTime:create(0.8),callback5 ))
    else
       self:runAction(cc.Sequence:create(cc.DelayTime:create(idleTime),callback4 ,cc.DelayTime:create(0.5),callback5 ))
    end
    
	--点数记录
	self.m_parent:getDataMgr().m_tabGameResult.m_cbIdlePoint = idlePoint
	self.m_parent:getDataMgr().m_tabGameResult.m_cbMasterPoint = masterPoint

	local nowCBWinner = g_var(cmd).AREA_MAX
	local nowCBKingWinner = g_var(cmd).AREA_MAX
    local masterFirst = g_var(GameLogic).GetCardValue(masterCards[1])
    local masterSecond = g_var(GameLogic).GetCardValue(masterCards[2])
    local idleFirst = g_var(GameLogic).GetCardValue(idleCards[1])
    local idleSecond = g_var(GameLogic).GetCardValue(idleCards[2])
    local nowBIdleTwoPair = false
	local nowBMasterTwoPair = false

	local cbBetAreaBlink = {0,0,0,0,0,0,0,0}
	if idlePoint > masterPoint then		
		self.m_enPointResult = kIdleWin

		--闲
		nowCBWinner = g_var(cmd).AREA_XIAN
		cbBetAreaBlink[g_var(cmd).AREA_XIAN + 1] = 1
		--闲天王修改为闲对
		if idleFirst == idleSecond then
			nowCBKingWinner = g_var(cmd).AREA_XIAN_DUI
            nowBIdleTwoPair = true
			cbBetAreaBlink[g_var(cmd).AREA_XIAN_TIAN + 1] = 1
		end
	elseif idlePoint < masterPoint then
		self.m_enPointResult = kMasterWin

		--庄
		nowCBWinner = g_var(cmd).AREA_ZHUANG
		cbBetAreaBlink[g_var(cmd).AREA_ZHUANG + 1] = 1
		if masterFirst == masterSecond then
			nowCBKingWinner = g_var(cmd).AREA_ZHUANG_DUI
            nowBMasterTwoPair = true
			cbBetAreaBlink[g_var(cmd).AREA_ZHUANG_TIAN + 1] = 1
		end
	elseif idlePoint == masterPoint then
		self.m_enPointResult = kDraw

		--平
		nowCBWinner = g_var(cmd).AREA_PING
		cbBetAreaBlink[g_var(cmd).AREA_PING + 1] = 1
		--判断是否为同点平
		local bAllPointSame = false
		if #idleCards == #masterCards then
			local cbCardIdx = 1
			for i = cbCardIdx, #idleCards do
				local cbBankerValue = g_var(GameLogic).GetCardValue(masterCards[cbCardIdx])
				local cbIdleValue = g_var(GameLogic).GetCardValue(idleCards[cbCardIdx])

				if cbBankerValue ~= cbIdleValue then
					break
				end

				if cbCardIdx == #masterCards then
					bAllPointSame = true
				end
			end
		end

	end

	--对子判断

	self.m_parent:getDataMgr().m_tabBetArea = cbBetAreaBlink

	local bJoin = self.m_parent:getDataMgr().m_bJoin
	local res = self.m_parent:getDataMgr().m_tabGameResult
	if nil ~= self.m_parent and false == yl.m_bDynamicJoin then
		--添加路单记录
		local rec = g_var(bjlDefine).getEmptyRecord()

        local serverrecord = g_var(bjlDefine).getEmptyServerRecord()
        serverrecord.cbKingWinner = nowCBKingWinner
        serverrecord.bPlayerTwoPair = nowBIdleTwoPair
        serverrecord.bBankerTwoPair = nowBMasterTwoPair
        serverrecord.cbPlayerCount = idlePoint
        serverrecord.cbBankerCount = masterPoint
        serverrecord.cbBetNum = self.m_parent.m_betNumPer
        rec.m_pServerRecord = serverrecord
        rec.m_cbGameResult = nowCBWinner
        
        rec.m_tagUserRecord.m_bJoin = bJoin
        if bJoin then        	
        	rec.m_tagUserRecord.m_bWin = res.m_llTotal > 0
        end

        self.m_parent:getDataMgr():addGameRecord(rec)
        --客户端计算分数(刷新小录单)
        --self.m_parent:refreshSample()
        --增加大录单刷新
        --self.m_parent:updateWallBill()
        
	end
	--刷新结果
    self:runAction(cc.Sequence:create(cc.DelayTime:create(3.4), cc.CallFunc:create(
                    function ()
                        self:refreshResult(self.m_enPointResult)
                    end
                )))
	--self:refreshResult(self.m_enPointResult)

	--播放音效
    self:runAction(cc.Sequence:create(cc.DelayTime:create(3.4), cc.CallFunc:create(
                    function ()
                         if true == bJoin then
		                    --
		                    if res.m_llTotal > 0 then
			                    --ExternalFun.playSoundEffect("END_WIN.wav")
                                --ExternalFun.playSoundEffect("END_DRAW.mp3")
		                    elseif res.m_llTotal < 0 then
			                    --ExternalFun.playSoundEffect("END_LOST.mp3")
		                    else
			                    --ExternalFun.playSoundEffect("END_DRAW.wav")
		                    end
	                    else
		                    --ExternalFun.playSoundEffect("END_DRAW.wav")
	                    end
                    end
                )))
	
end

function GameCardLayer:addCards( cbCard, dir, pCallBack )
	--print("on add card=============:" .. g_var(GameLogic).GetCardValue(cbCard) .. ";dir " .. dir)
	if nil == self.m_tabCards[dir] then
		return
	end

	if nil ~= pCallBack then
		pCallBack:retain()
	end
	self.m_tabCards[dir]:addCards(cbCard, pCallBack)
end

function GameCardLayer:refreshPoint( dir )
	if nil == self.m_tabCards[dir] then
		return
	end
	local handCards = self.m_tabCards[dir]:getHandCards()

	--切换动画
	local sca = cc.ScaleTo:create(0.2,0.0001,1)
	local call = cc.CallFunc:create(function ()
		local point = g_var(GameLogic).GetCardListPip(handCards)
		local str = string.format("clearing_%d.png", point)
		--local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
		--if nil ~= frame then
		--	self.m_tabPoint[dir]:setSpriteFrame(frame)
        --print("-----refreshPoint------",dir,point)
        self.m_tabPoint[dir]:setString(point)
		--end
	end)
	local sca2 = cc.ScaleTo:create(0.2,1)
	local seq = cc.Sequence:create(sca, call, sca2)
	self.m_tabPoint[dir]:stopAllActions()
	self.m_tabPoint[dir]:runAction(seq)
end

function GameCardLayer:refreshResult( enResult )
	local call_switch = cc.CallFunc:create(function()
		self:switchLayout(true)
	end)
	if kDraw == enResult then
        ExternalFun.playSoundEffect("ping.mp3")
	elseif kIdleWin == enResult then
        ExternalFun.playSoundEffect("xianwin.mp3")
	elseif kMasterWin == enResult then
        ExternalFun.playSoundEffect("zuanwin.mp3")
	end

	if self.m_parent.m_isEndScene == false then
		
    	self.m_parent:refreshSample()
    end
    self.m_parent:updateWallBill()
end

function GameCardLayer:noticeTips(  )
	local m_nTotalCount = self.m_nTotalCount
	local m_nDispatchedCount = self.m_nDispatchedCount

	if m_nTotalCount > 4 then
		if m_nDispatchedCount >= 4 and nil ~= self.m_scheduler then
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
			local call = cc.CallFunc:create(function()
				self:onAnimationEnd()
			end)
			local seq = cc.Sequence:create(cc.DelayTime:create(DELAY_TIME), call)
			self:stopAllActions()
			self:runAction(seq)
		end

		local idleCards = self.m_tabCards[kLEFT_ROLE]:getHandCards()
		--g_var(GameLogic).SortCardList(idleCards, GameLogic.ST_ORDER)
		local idlePoint = g_var(GameLogic).GetCardListPip(idleCards)

		local masterCards = self.m_tabCards[kRIGHT_ROLE]:getHandCards()
		--g_var(GameLogic).SortCardList(masterCards, GameLogic.ST_ORDER)
		local masterPoint = g_var(GameLogic).GetCardListPip(masterCards)
        --local masterPoint = cc.p(550,160)
		local idleCount = #idleCards
		local masterCount = #masterCards
		local str = ""
		if m_nDispatchedCount == 4 then
			if idleCount == 2 and (6 == idlePoint or 7 == idlePoint) then
				str = string.format("闲前两张 %d 点,庄 %d 点,庄继续拿牌", idlePoint, masterPoint)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("zuanbu.mp3")
                    end
                )))
                --ExternalFun.playSoundEffect("zuanbu.wav")
			elseif idleCount == 2 and idlePoint < 6 then
				str = string.format("闲 %d 点, 庄 %d 点,闲继续拿牌", idlePoint, masterPoint)
                --ExternalFun.playSoundEffect("xianbu.wav")
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("xianbu.mp3")
                    end
                )))
			elseif idleCount == 2 and (masterPoint >= 3 and masterPoint <= 5) then
				str = string.format("闲不补牌, 庄 %d 点,闲继续拿牌", masterPoint)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("xianbu.mp3")
                    end
                )))
                --ExternalFun.playSoundEffect("xianbu.wav")
			end
		elseif m_nDispatchedCount == 5 then
			if idleCount == 3 and masterCount == 2 and m_nTotalCount == 6 then
				local cbValue = g_var(GameLogic).GetCardPip(idleCards[3])
				str = string.format("闲第三张牌 %d 点,庄 %d 点,庄继续拿牌", cbValue, masterPoint)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
                    function ()
                         ExternalFun.playSoundEffect("zuanbu.mp3")
                    end
                )))
                --ExternalFun.playSoundEffect("zuanbu.wav")
			end
		end

		if "" ~= str then
			showToast(nil,str,1)
		end
	end
end

--调整显示界面 bDisOver 是否发牌结束
function GameCardLayer:switchLayout( bDisOver )
	if bDisOver then 
        self:cardMoveAni()
	else
		--回位
		self.m_tabCards[kLEFT_ROLE]:stopAllActions()
		self.m_tabCards[kLEFT_ROLE]:setScale(0.75)
		self.m_tabCards[kLEFT_ROLE]:setPosition(330, 640)
		self.m_tabCards[kRIGHT_ROLE]:stopAllActions()
		self.m_tabCards[kRIGHT_ROLE]:setScale(0.75)
		self.m_tabCards[kRIGHT_ROLE]:setPosition(980, 640)
	end
end

function GameCardLayer:cardMoveAni(  )
	--扑克、点数，移动位置
	self.m_tabCards[kLEFT_ROLE]:stopAllActions()
	local move = cc.MoveTo:create(0.2, cc.p(450,680))
	local scal = cc.ScaleTo:create(0.2, 0.75)
	local spa = cc.Spawn:create(move, scal)
	--self.m_tabCards[kLEFT_ROLE]:runAction(spa)
    self.m_tabCards[kLEFT_ROLE]:runAction(scal)

	self.m_tabCards[kRIGHT_ROLE]:stopAllActions()
	move = cc.MoveTo:create(0.2, cc.p(1010,680))
	scal = cc.ScaleTo:create(0.2, 0.75)
	spa = cc.Spawn:create(move, scal)
    self.m_tabCards[kRIGHT_ROLE]:runAction(scal)
end

return GameCardLayer
