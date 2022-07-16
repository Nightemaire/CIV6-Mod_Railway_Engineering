-- RailroadConstruction
-- Author: Nightemaire
-- DateCreated: 6/18/2022 6:35:56 PM
--------------------------------------------------------------

print("RAILROAD CONSTRUCTION SCRIPT LOADED! 18:23")

local Railroad = GameInfo.Routes["ROUTE_RAILROAD"];
local iRailBuilder = GameInfo.Units["UNIT_RAILROAD_BUILDER"].Index;
local iRailyard = GameInfo.Buildings["BUILDING_RAILYARD"].Index;
local iFactory = GameInfo.Buildings["BUILDING_FACTORY"].Index;
local iWorkshop = GameInfo.Buildings["BUILDING_WORKSHOP"].Index;
local iIndustrialZone = GameInfo.Districts["DISTRICT_INDUSTRIAL_ZONE"].Index;
--local iTheodoreJudah = GameInfo.GreatPersonIndividuals["GREAT_PERSON_INDIVIDUAL_THEODORE_JUDAH"].Index;

local buildTracker = {}
local JudahTrackerX = -1
local JudahTrackerY = -1

function OnUnitMoved(playerID:number, unitID, tileX, tileY)
	local unit = UnitManager.GetUnit(playerID, unitID)
	local unitType = GameInfo.Units[unit:GetType()].Index

	if (unitType == iRailBuilder) then
		
		local coal = getPlayer(playerID):GetResources():GetResourceAmount("RESOURCE_COAL");
		--print("Player has "..coal.." coal stockpiled");
		
		local plot = Map.GetPlot(tileX, tileY);
		local routeType = plot:GetRouteType();
		
		if (not plot:IsWater() and not(routeType == Railroad.Index) and HasAdjacentRailroad(plot)) and coal > 0 then
			RouteBuilder.SetRouteType(plot, Railroad.Index);
			local charges = buildTracker[playerID][unitID]
			buildTracker[playerID][unitID] = charges - 1;
			if (charges <= 0) then				
				print("Charges gone, destroying Rail Builder");
				UnitManager.Kill(unit);
				buildTracker[playerID][unitID] = nil;
			else
				--print("Rail Builder has "..buildTracker[playerID][unitID].." charges remaining");
			end
		end
	end

	if(unit:IsGreatPerson() == true) then
		local greatperson = unit:GetGreatPerson():GetIndividualHash();
		if(GameInfo.GreatPersonIndividuals["GREAT_PERSON_INDIVIDUAL_THEODORE_JUDAH"].Hash == greatperson) then
			--print("Judah Moved!!  "..tileX..", "..tileY);
			JudahTrackerX = tileX;
			JudahTrackerY = tileY;
		end
	end
end

function OnUnitAdded(playerID : number, unitID : number)
	local unit = getPlayer(playerID):GetUnits():FindID(unitID);
	if unit ~= nil then
		local unitType = GameInfo.Units[unit:GetType()].Index
	
		if (unitType == iRailBuilder) then
			print("Railbuilder added")
			--unit["BuildsRemaining"] = 10;
			--printArgTable(unit)

			if buildTracker[playerID] == nil then
				buildTracker[playerID] = {}
			end

			buildTracker[playerID][unitID] = 10;

			-- get the industrial zone tile and move the unit there
			local tileX = unit:GetX()
			local tileY = unit:GetY()
			local city = CityManager.GetCityAt(tileX, tileY)

			if (city ~= nil) then
				Plots = city:GetOwnedPlots();	
				--print("RAILWAYS: Plots is "..#(Plots).." long");
			else
				print("City was NIL OnUnitAdded");
			end

			local IZ_X, IZ_Y = getIndustrialZoneTile(city)

			-- Build a railroad on the industrial zone (just in case it wasn't already built) and move the builder there
			local plot = Map.GetPlot(IZ_X, IZ_Y);
			RouteBuilder.SetRouteType(plot, Railroad.Index);
			UnitManager.PlaceUnit(unit, IZ_X, IZ_Y)
		end
	end
end

function OnGreatPersonActivation(playerID:number, unitID, greatPersonClassID:number, greatPersonIndividualID)
	local unit = getPlayer(playerID):GetUnits():FindID(unitID);
	local unitType = GameInfo.Units[unit:GetType()].Index

	print("Great Person Activated with ID: "..greatPersonIndividualID);
	
	local greatperson = unit:GetGreatPerson():GetIndividualHash();
	--print("Individual: ", greatperson);
	if(GameInfo.GreatPersonIndividuals["GREAT_PERSON_INDIVIDUAL_THEODORE_JUDAH"].Hash == greatperson) then	
		print("Judah activated at:  "..JudahTrackerX..", "..JudahTrackerY);
		local district = CityManager.GetDistrictAt(JudahTrackerX, JudahTrackerY)
		local city = district:GetCity()

		if (city ~= nil) then	
			UpgradeCityToRailroads(city)
		else
			print("City was NIL OnGreatPersonActivation");
		end
	end
end

function OnBuildingConstructed(playerID:number, cityID, buildingID, plotID, bOriginalConstruction)
	if bOriginalConstruction then
		if (buildingID == iRailyard) then
			local plot = Map.GetPlotByIndex(plotID)
			RouteBuilder.SetRouteType(plot, Railroad.Index);

			--local player = getPlayer(playerID)
			-- Spawn a free railbuilder for the AI, because they probably won't build one themselves
			--if player:IsAI() then
				--player:GetUnits():Create(iRailBuilder, plot:GetX(), plot:GetY());
			--end
		end
	end
end

function UpgradeCityToRailroads(city)
	local Plots = city:GetOwnedPlots();
	--tprint(Plots, 0);
	local plotCount = #(Plots)
	
	print("There are "..plotCount.." plots belonging to the city of "..city:GetName());

	for k,plot in pairs(Plots) do
		local routeType = plot:GetRouteType();
		local plotX = plot:GetX();
		local plotY = plot:GetY();
		print("Plot at "..plotX..", "..plotY.." has a route type of "..routeType);
		if (plot:IsRoute()) then
			print("The plot is a route, making it a railroad");
			RouteBuilder.SetRouteType(plot, Railroad.Index);
		end
	end
end

-- ACCESS
function getIndustrialZoneTile(city)
	local locX = -1;
	local locY = -1;
	local IZ = city:GetDistricts():GetDistrict(iIndustrialZone)
		locX = IZ:GetX();
		locY = IZ:GetY();
	return locX, locY;
end

function getCity(playerID, cityID)
	return getPlayer(playerID):GetCities():FindID(cityID);
end

function getPlayer(playerID)
	return PlayerManager.GetPlayer(playerID)
end

function HasAdjacentRailroad(plot)
	local startX = plot:GetX();
	local startY = plot:GetY();
	--print("Start = {"..startX..", "..startY.."}")
	for i = 0, 5 do
		adjPlot = Map.GetAdjacentPlot(startX, startY, i)
		--print ("Adj = {"..adjPlot:GetX()..", "..adjPlot:GetY().."}")
		local routeType = adjPlot:GetRouteType();
		if adjPlot and routeType == Railroad.Index then return true; end
	end
	return false;
end

function GenerateTheodore()
	local individual = GameInfo.GreatPersonIndividuals["GREAT_PERSON_INDIVIDUAL_THEODORE_JUDAH"].Hash;
	local class = GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_ENGINEER"].Hash;
	local era = GameInfo.Eras["ERA_INDUSTRIAL"].Hash;
	local cost = 0;
	return Game.GetGreatPeople():GrantPerson(individual, class, era, cost, 0, false);
end

-- UTILITY
function printArgTable(argTable)
	if (argTable ~= nil) then
		for k,v in ipairs(argTable) do
			print("Arg "..k..": "..v)
		end
	end
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end

Events.UnitAddedToMap.Add(OnUnitAdded);
Events.UnitMoved.Add(OnUnitMoved);
Events.UnitGreatPersonActivated.Add(OnGreatPersonActivation);
--GameEvents.PlayerTurnStarted.Add(OnPlayerTurnActivated);
--Events.BuildingAddedToMap.Add(OnBuildingAdded);
GameEvents.BuildingConstructed.Add(OnBuildingConstructed);

print("RAILROAD SCRIPT DONE");